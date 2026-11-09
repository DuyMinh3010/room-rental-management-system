"use strict";
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { createHash } = require("node:crypto");
const B = require("./billing");
initializeApp();
setGlobalOptions({ region: "asia-southeast1", maxInstances: 5 });
const db = getFirestore(),
  stamp = () => FieldValue.serverTimestamp();
const ref = (c, id) => db.collection(c).doc(id);
const value = (s) => (s.exists ? { ...s.data(), _id: s.id } : null);
function text(v, label, optional = false) {
  if (optional && (v === null || v === undefined || v === "")) return "";
  if (typeof v !== "string" || !v.trim() || v.length > 4000)
    throw new Error(`Vui lòng nhập ${label}`);
  return v.trim();
}
function id(v) {
  if (typeof v !== "string" || !v || v.includes("/") || v.length > 200)
    throw new Error("ID không hợp lệ");
  return v;
}
function hash(v) {
  return createHash("sha256")
    .update(v.trim().normalize("NFC").toLocaleLowerCase("vi"))
    .digest("hex");
}
async function manager(uid) {
  if (!uid) throw new HttpsError("unauthenticated", "Bạn cần đăng nhập.");
  const s = await ref("managers", uid).get();
  if (!s.exists || s.data().enabled !== true)
    throw new HttpsError(
      "permission-denied",
      "UID này chưa được cấp quyền quản lý.",
    );
}
function bump(tx, roomId) {
  if (roomId)
    tx.update(ref("rooms", roomId), {
      billingRevision: FieldValue.increment(1),
      updatedAt: stamp(),
    });
}
function notify(tx, key, title, body, extra = {}) {
  tx.set(ref("notifications", key), {
    title,
    body,
    audience: "managers",
    createdAt: stamp(),
    pushStatus: "pending",
    ...extra,
  });
}
function owned(d, ownerId, label) {
  found(d, label);
  if (d.ownerId !== ownerId)
    throw new Error(`${label} không thuộc tài khoản chủ trọ này`);
  return d;
}
const ownerQuery = (collection, ownerId, field, value) =>
  db
    .collection(collection)
    .where("ownerId", "==", ownerId)
    .where(field, "==", value);
function num(v, label, min = 0, integer = true) {
  return B.finite(v, label, { min, integer });
}
function found(d, label) {
  if (!d || d.archived)
    throw new Error(`${label} không tồn tại hoặc đã lưu trữ`);
  return d;
}
const active = (c) => ["active", "scheduled"].includes(c.status);

// Nhận thao tác ghi từ app. Client không được ghi thẳng dữ liệu nghiệp vụ.
exports.manage = onCall({ timeoutSeconds: 120 }, async (req) => {
  await manager(req.auth?.uid);
  const a = req.data || {},
    action = a.action,
    d = a.data || {},
    ownerId = req.auth.uid;
  try {
    if (action === "previewInvoice")
      return await invoice(ownerId, a.roomId, B.period(a.period), false);
    if (action === "issueInvoice")
      return await invoice(ownerId, a.roomId, B.period(a.period), true);
    if (action === "runBilling") return await runBilling(ownerId);
    if (action === "migrateServiceIds") return await migrateServiceIds(ownerId);
    if (action === "migrateOwnerData") return await migrateOwnerData(ownerId);
    if (action === "migrateLegacy")
      return await migrateLegacy(ownerId, a.apply === true);
    if (action === "linkTenantAccount") {
      const t = await ref("tenants", id(a.id)).get();
      owned(value(t), ownerId, "Người thuê");
      const email = text(a.email, "email");
      let u;
      try {
        u = await getAuth().getUserByEmail(email);
      } catch {
        throw new Error(
          "Email chưa có trong Authentication. Hãy tạo tài khoản trước.",
        );
      }
      await db.runTransaction(async (tx) => {
        const q = await tx.get(
          ownerQuery("contracts", ownerId, "tenantId", a.id),
        );
        tx.update(t.ref, { authUid: u.uid, email, updatedAt: stamp() });
        for (const c of q.docs)
          if (active(c.data()))
            tx.update(c.ref, { recipientUid: u.uid, updatedAt: stamp() });
      });
      return { uid: u.uid };
    }
    return await db.runTransaction(async (tx) => {
      const key = a.id ? id(a.id) : db.collection("_").doc().id;
      if (action === "saveRoom") {
        const r = ref("rooms", key),
          old = value(await tx.get(r));
        if (old) owned(old, ownerId, "Phòng");
        const name = text(d.name, "tên phòng"),
          lock = ref("roomNames", `${ownerId}_${hash(name)}`);
        const [taken, duplicates, tenants] = await Promise.all([
          tx.get(lock),
          tx.get(ownerQuery("rooms", ownerId, "name", name)),
          tx.get(ownerQuery("tenants", ownerId, "roomId", key)),
        ]);
        if (
          (taken.exists && taken.data().roomId !== key) ||
          duplicates.docs.some(
            (x) => x.id !== key && !x.data().archived,
          )
        )
          throw new Error("Tên phòng đã tồn tại");
        const condition = text(d.condition, "tình trạng");
        if (!["Tốt", "Đang sửa"].includes(condition))
          throw new Error("Tình trạng phải là Tốt hoặc Đang sửa");
        const capacity = num(d.capacity, "số người tối đa", 1);
        if (capacity > 100) throw new Error("Tối đa 100 người/phòng");
        const count = tenants.docs.filter((x) => !x.data().archived).length;
        if (count > capacity)
          throw new Error("Số người tối đa nhỏ hơn số người đang ở");
        const day = num(d.billingDay, "ngày chốt", 1);
        if (day > 31) throw new Error("Ngày chốt từ 1–31");
        const term = num(d.paymentTermDays, "số ngày thanh toán");
        if (term > 60) throw new Error("Hạn thanh toán tối đa 60 ngày");
        if (old && old.name !== name)
          tx.delete(ref("roomNames", `${ownerId}_${hash(old.name || key)}`));
        tx.set(lock, { ownerId, roomId: key });
        tx.set(
          r,
          {
            ownerId,
            name,
            condition,
            status: condition,
            capacity,
            people: count,
            area: num(d.area, "diện tích", 0.1, false),
            price: num(d.price, "giá thuê", 1),
            deposit: num(d.deposit, "tiền cọc"),
            billingDay: `${String(day).padStart(2, "0")} hàng tháng`,
            paymentTermDays: term,
            description: text(d.description, "mô tả", true),
            zone: FieldValue.delete(),
            archived: false,
            serviceIds: old?.serviceIds || [],
            imageUrls: old?.imageUrls || [],
            createdAt: old?.createdAt || stamp(),
            updatedAt: stamp(),
            billingRevision: FieldValue.increment(1),
          },
          { merge: true },
        );
        return { id: key };
      }
      if (action === "archiveRoom") {
        const r = ref("rooms", id(a.id)),
          room = owned(value(await tx.get(r)), ownerId, "Phòng");
        const [ts, cs, bs] = await Promise.all(
          ["tenants", "contracts", "invoices"].map((c) =>
            tx.get(ownerQuery(c, ownerId, "roomId", a.id)),
          ),
        );
        if (
          ts.docs.some((x) => !x.data().archived) ||
          cs.docs.some((x) => active(x.data())) ||
          bs.docs.some((x) => ["unpaid", "reported"].includes(x.data().status))
        )
          throw new Error(
            "Cần chuyển người thuê, kết thúc hợp đồng và xử lý hóa đơn chưa trả trước",
          );
        tx.update(r, { archived: true, updatedAt: stamp() });
        tx.delete(ref("roomNames", `${ownerId}_${hash(room.name)}`));
        return { id: a.id };
      }
      if (action === "saveTenant" || action === "archiveTenant") {
        const r = ref("tenants", key),
          old = value(await tx.get(r));
        if (old) owned(old, ownerId, "Người thuê");
        const roomId =
          action === "archiveTenant" ? "" : text(d.roomId, "phòng", true);
        const tenantEmail =
          action === "archiveTenant" ? "" : text(d.email, "email", true).toLowerCase();
        if (
          tenantEmail &&
          !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(tenantEmail)
        )
          throw new Error("Email người thuê không hợp lệ");
        if (action === "saveTenant" && old?.authUid && tenantEmail !== old.email)
          throw new Error(
            "Hồ sơ đã liên kết tài khoản. Không đổi email tại đây; hãy cập nhật email của tài khoản đã liên kết.",
          );
        const nextRoom = roomId
          ? owned(value(await tx.get(ref("rooms", id(roomId)))), ownerId, "Phòng")
          : null;
        const oldRoomId = old?.roomId || "";
        if (oldRoomId && oldRoomId !== roomId)
          owned(
            value(await tx.get(ref("rooms", oldRoomId))),
            ownerId,
            "Phòng",
          );
        const [cs, others] = await Promise.all([
          tx.get(ownerQuery("contracts", ownerId, "tenantId", key)),
          roomId
            ? tx.get(ownerQuery("tenants", ownerId, "roomId", roomId))
            : Promise.resolve(null),
        ]);
        if (cs.docs.some((x) => active(x.data()) && x.data().roomId !== roomId))
          throw new Error(
            "Người thuê có hợp đồng đang dùng. Kết thúc hợp đồng trước khi chuyển/xóa",
          );
        if (
          nextRoom &&
          (nextRoom.condition === "Đang sửa" || nextRoom.status === "Đang sửa")
        )
          throw new Error("Phòng đang sửa, chưa thể nhận người");
        const nextCount =
          (others?.docs.filter((x) => x.id !== key && !x.data().archived)
            .length || 0) + 1;
        if (nextRoom && nextCount > Number(nextRoom.capacity || 100))
          throw new Error("Phòng đã đủ số người tối đa");
        if (action === "archiveTenant") {
          found(old, "Người thuê");
          tx.update(r, {
            ownerId,
            archived: true,
            roomId: "",
            updatedAt: stamp(),
          });
        } else
          tx.set(
            r,
            {
              ownerId,
              name: text(d.name, "họ tên"),
              phone: text(d.phone, "số điện thoại"),
              email: tenantEmail,
              identity: text(d.identity, "CCCD", true),
              birthday: text(d.birthday, "ngày sinh", true),
              address: text(d.address, "địa chỉ", true),
              note: text(d.note, "ghi chú", true),
              roomId,
              archived: false,
              authUid: old?.authUid || "",
              createdAt: old?.createdAt || stamp(),
              updatedAt: stamp(),
            },
            { merge: true },
          );
        if (nextRoom)
          tx.update(ref("rooms", roomId), {
            people: nextCount,
            billingRevision: FieldValue.increment(1),
          });
        if (oldRoomId && oldRoomId !== roomId)
          tx.update(ref("rooms", oldRoomId), {
            people: FieldValue.increment(-1),
            billingRevision: FieldValue.increment(1),
          });
        return { id: key };
      }
      if (action === "saveService" || action === "archiveService") {
        const r = ref("services", key),
          old = value(await tx.get(r));
        if (old) owned(old, ownerId, "Dịch vụ");
        const rooms = await tx.get(
          db
            .collection("rooms")
            .where("ownerId", "==", ownerId)
            .where("serviceIds", "array-contains", key),
        );
        if (action === "archiveService") {
          found(old, "Dịch vụ");
          if (rooms.docs.some((x) => !x.data().archived))
            throw new Error("Bỏ áp dụng dịch vụ khỏi các phòng trước khi xóa");
          tx.update(r, { archived: true, updatedAt: stamp() });
          return { id: key };
        }
        const mode = text(d.mode, "cách tính");
        if (!["meter", "room", "person"].includes(mode))
          throw new Error("Cách tính không hợp lệ");
        if (
          old &&
          old.mode !== mode &&
          rooms.docs.some((x) => !x.data().archived)
        )
          throw new Error("Bỏ dịch vụ khỏi phòng trước khi đổi cách tính");
        tx.set(
          r,
          {
            id: key,
            ownerId,
            name: text(d.name, "tên dịch vụ"),
            mode,
            price: num(d.price, "đơn giá"),
            unit: text(d.unit, "đơn vị"),
            note: text(d.note, "ghi chú", true),
            archived: false,
            createdAt: old?.createdAt || stamp(),
            updatedAt: stamp(),
          },
          { merge: true },
        );
        for (const x of rooms.docs) bump(tx, x.id);
        return { id: key };
      }
      if (action === "assignServices") {
        const roomId = id(a.roomId),
          r = ref("rooms", roomId);
        owned(value(await tx.get(r)), ownerId, "Phòng");
        if (!Array.isArray(a.serviceIds) || a.serviceIds.length > 30)
          throw new Error("Tối đa 30 dịch vụ/phòng");
        const ids = [...new Set(a.serviceIds.map(id))];
        for (const x of ids)
          owned(
            value(await tx.get(ref("services", x))),
            ownerId,
            "Dịch vụ",
          );
        tx.update(r, {
          serviceIds: ids,
          updatedAt: stamp(),
          billingRevision: FieldValue.increment(1),
        });
        return { id: roomId };
      }
      if (action === "saveMeter") {
        const roomId = id(d.roomId),
          serviceId = id(d.serviceId),
          p = B.period(d.period),
          r = ref("rooms", roomId);
        const room = found(value(await tx.get(r)), "Phòng"),
          service = found(
            value(await tx.get(ref("services", serviceId))),
            "Dịch vụ",
          );
        owned(room, ownerId, "Phòng");
        owned(service, ownerId, "Dịch vụ");
        if (
          service.mode !== "meter" ||
          !(room.serviceIds || []).includes(serviceId)
        )
          throw new Error("Dịch vụ chỉ số chưa áp dụng cho phòng này");
        const mref = ref("meters", `${roomId}_${serviceId}_${p}`),
          old = value(await tx.get(mref));
        const prev = value(
          await tx.get(
            ref("meters", `${roomId}_${serviceId}_${B.previousPeriod(p)}`),
          ),
        );
        const next = value(
          await tx.get(
            ref("meters", `${roomId}_${serviceId}_${B.nextPeriod(p)}`),
          ),
        );
        if (p > B.today().slice(0, 7))
          throw new Error("Chưa nhập chỉ số cho tháng tương lai");
        const bills = await tx.get(
          ownerQuery("invoices", ownerId, "roomId", roomId),
        );
        if (
          bills.docs.some(
            (x) => x.data().meterPeriod === p && x.data().status !== "void",
          )
        )
          throw new Error(
            "Kỳ này đã phát hành hóa đơn. Không sửa chỉ số lịch sử",
          );
        const previous = num(
            prev?.current ?? d.previous,
            "chỉ số cũ",
            0,
            false,
          ),
          current = num(d.current, "chỉ số mới", 0, false);
        if (current < previous)
          throw new Error("Chỉ số mới phải lớn hơn hoặc bằng chỉ số cũ");
        if (next && Number(next.previous) !== current)
          throw new Error(
            "Kỳ sau đã có chỉ số phụ thuộc, không sửa chỉ số kỳ này",
          );
        tx.set(mref, {
          ownerId,
          roomId,
          serviceId,
          period: p,
          previous,
          current,
          usage: Number((current - previous).toFixed(3)),
          serviceName: service.name,
          unit: service.unit,
          createdAt: old?.createdAt || stamp(),
          updatedAt: stamp(),
        });
        bump(tx, roomId);
        return { id: mref.id };
      }
      if (action === "saveContract") {
        const r = ref("contracts", key),
          old = value(await tx.get(r));
        if (old) owned(old, ownerId, "Hợp đồng");
        if (
          old &&
          ["active", "ended", "expired", "cancelled"].includes(old.status)
        )
          throw new Error(
            "Hợp đồng đã có hiệu lực không sửa nội dung; kết thúc và lập hợp đồng mới để giữ lịch sử",
          );
        const roomId = id(d.roomId),
          tenantId = id(d.tenantId);
        const room = owned(
            value(await tx.get(ref("rooms", roomId))),
            ownerId,
            "Phòng",
          ),
          tenant = owned(
            value(await tx.get(ref("tenants", tenantId))),
            ownerId,
            "Người thuê",
          );
        const cs = await tx.get(
          ownerQuery("contracts", ownerId, "roomId", roomId),
        );
        const number = text(d.number, "số hợp đồng"),
          lock = ref("contractNumbers", `${ownerId}_${hash(number)}`);
        const occupied = await tx.get(lock);
        const duplicates = await tx.get(
          ownerQuery("contracts", ownerId, "number", number),
        );
        if (
          (occupied.exists && occupied.data().contractId !== key) ||
          duplicates.docs.some((x) => x.id !== key)
        )
          throw new Error("Số hợp đồng đã tồn tại");
        const startDate = B.date(d.startDate),
          endDate = B.date(d.endDate);
        if (startDate > endDate || endDate < B.today())
          throw new Error("Thời hạn hợp đồng không hợp lệ");
        if (tenant.roomId !== roomId)
          throw new Error("Chọn người thuê đang được gán vào phòng này");
        if (room.condition === "Đang sửa" || room.status === "Đang sửa")
          throw new Error("Phòng đang sửa chưa thể tạo hợp đồng");
        if (
          cs.docs.some(
            (x) =>
              x.id !== key &&
              active(x.data()) &&
              x.data().startDate <= endDate &&
              x.data().endDate >= startDate,
          )
        )
          throw new Error("Phòng có hợp đồng trùng thời hạn");
        if (old?.number && old.number !== number)
          tx.delete(
            ref("contractNumbers", `${ownerId}_${hash(old.number)}`),
          );
        const status = startDate > B.today() ? "scheduled" : "active";
        tx.set(lock, { ownerId, contractId: key });
        tx.set(
          r,
          {
            ownerId,
            number,
            roomId,
            roomName: room.name,
            tenantId,
            tenantName: tenant.name,
            recipientUid: tenant.authUid || "",
            startDate,
            endDate,
            rent: num(room.price, "giá thuê phòng", 1),
            deposit: num(room.deposit, "tiền cọc phòng"),
            status,
            note: text(d.note, "ghi chú", true),
            createdAt: old?.createdAt || stamp(),
            updatedAt: stamp(),
          },
          { merge: true },
        );
        bump(tx, roomId);
        return { id: key };
      }
      if (action === "endContract") {
        const r = ref("contracts", id(a.id)),
          c = owned(value(await tx.get(r)), ownerId, "Hợp đồng");
        if (!active(c)) throw new Error("Hợp đồng đã kết thúc");
        const bs = await tx.get(
          ownerQuery("invoices", ownerId, "contractId", a.id),
        );
        if (
          bs.docs.some((x) => ["unpaid", "reported"].includes(x.data().status))
        )
          throw new Error("Còn hóa đơn chưa thanh toán, cần xử lý trước");
        const day = B.today();
        tx.update(r, {
          status: c.status === "scheduled" ? "cancelled" : "ended",
          endedOn: day,
          updatedAt: stamp(),
        });
        bump(tx, c.roomId);
        return { id: a.id };
      }
      if (action === "saveExtra" || action === "deleteExtra") {
        const xref = ref("extras", key),
          old = value(await tx.get(xref));
        if (old) owned(old, ownerId, "Phụ phí");
        const roomId = id(d.roomId || old?.roomId);
        owned(value(await tx.get(ref("rooms", roomId))), ownerId, "Phòng");
        const p = B.period(d.period || old?.period);
        const bs = await tx.get(
          ownerQuery("invoices", ownerId, "roomId", roomId),
        );
        if (
          bs.docs.some(
            (x) => x.data().period === p && x.data().status !== "void",
          )
        )
          throw new Error("Kỳ đã phát hành; không đổi phụ phí sau khi gửi");
        if (action === "deleteExtra") tx.delete(xref);
        else
          tx.set(xref, {
            ownerId,
            roomId,
            period: p,
            reason: text(d.reason, "lý do phụ phí"),
            amount: num(d.amount, "số tiền phụ phí", 1),
            createdAt: old?.createdAt || stamp(),
            updatedAt: stamp(),
          });
        bump(tx, roomId);
        return { id: key };
      }
      if (action === "saveMaintenance") {
        const r = ref("maintenance", key),
          old = value(await tx.get(r)),
          roomId = id(d.roomId);
        if (old) owned(old, ownerId, "Yêu cầu sửa chữa");
        owned(value(await tx.get(ref("rooms", roomId))), ownerId, "Phòng");
        const status = d.status || "new";
        if (!["new", "working", "done", "cancelled"].includes(status))
          throw new Error("Trạng thái không hợp lệ");
        tx.set(
          r,
          {
            ownerId,
            roomId,
            title: text(d.title, "vấn đề"),
            description: text(d.description, "mô tả"),
            cost: num(d.cost || 0, "chi phí"),
            status,
            imageUrls: old?.imageUrls || [],
            createdAt: old?.createdAt || stamp(),
            updatedAt: stamp(),
          },
          { merge: true },
        );
        // Tình trạng phòng được chủ trọ đổi riêng, tránh một yêu cầu sửa xong che mất yêu cầu khác.
        return { id: key };
      }
      if (action === "resendInvoice") {
        const r = ref("invoices", id(a.id)),
          bill = owned(value(await tx.get(r)), ownerId, "Hóa đơn");
        const tenant = owned(
          value(await tx.get(ref("tenants", id(bill.tenantId)))),
          ownerId,
          "Người thuê",
        );
        if (!tenant.authUid)
          throw new Error("Liên kết tài khoản người thuê trước khi gửi");
        if (bill.status === "void") throw new Error("Không gửi hóa đơn đã hủy");
        const count = (bill.resendCount || 0) + 1;
        tx.update(r, {
          recipientUid: tenant.authUid,
          delivered: true,
          resendCount: count,
          updatedAt: stamp(),
        });
        notify(
          tx,
          `resent_${a.id}_${count}`,
          "Hóa đơn tiền phòng",
          `${bill.roomName} · ${bill.period}: ${bill.total.toLocaleString("vi-VN")}đ`,
          {
            ownerId,
            audience: "tenant",
            recipientUid: tenant.authUid,
            invoiceId: a.id,
          },
        );
        return { id: a.id };
      }
      if (action === "confirmPayment" || action === "voidInvoice") {
        const r = ref("invoices", id(a.id)),
          bill = owned(value(await tx.get(r)), ownerId, "Hóa đơn");
        if (bill.status === "paid" || bill.status === "void")
          throw new Error("Hóa đơn đã thanh toán hoặc đã hủy");
        if (action === "voidInvoice") {
          tx.update(r, {
            status: "void",
            voidReason: text(a.reason, "lý do hủy"),
            updatedAt: stamp(),
          });
          if (bill.recipientUid)
            notify(
              tx,
              `void_${a.id}`,
              "Hóa đơn đã hủy",
              `${bill.roomName} · ${bill.period}`,
              {
                ownerId,
                audience: "tenant",
                recipientUid: bill.recipientUid,
                invoiceId: a.id,
              },
            );
        } else {
          const method = text(a.method, "hình thức thanh toán");
          if (!["cash", "bank"].includes(method))
            throw new Error("Hình thức không hợp lệ");
          tx.update(r, {
            status: "paid",
            paidAt: stamp(),
            paidDate: B.today(),
            method,
            confirmedBy: req.auth.uid,
            updatedAt: stamp(),
          });
          notify(
            tx,
            `paid_manager_${a.id}`,
            "Đã thanh toán hóa đơn",
            `${bill.roomName}: ${bill.total.toLocaleString("vi-VN")}đ`,
            { ownerId, invoiceId: a.id },
          );
          if (bill.recipientUid)
            notify(
              tx,
              `paid_tenant_${a.id}`,
              "Chủ trọ đã xác nhận thanh toán",
              `${bill.roomName} · ${bill.period}`,
              {
                ownerId,
                audience: "tenant",
                recipientUid: bill.recipientUid,
                invoiceId: a.id,
              },
            );
        }
        return { id: a.id };
      }
      if (action === "saveSettings") {
        tx.set(
          ref("settings", ownerId),
          {
            ownerId,
            name: text(d.name, "tên chủ trọ"),
            phone: text(d.phone, "số điện thoại"),
            address: text(d.address, "địa chỉ", true),
            bankName: text(d.bankName, "ngân hàng", true),
            bankAccount: text(d.bankAccount, "số tài khoản", true),
            bankHolder: text(d.bankHolder, "chủ tài khoản", true),
            autoBilling: d.autoBilling === true,
            updatedAt: stamp(),
          },
          { merge: true },
        );
        return { id: ownerId };
      }
      if (action === "addPhoto") {
        if (!["rooms", "maintenance"].includes(a.collection))
          throw new Error("Không hỗ trợ ảnh ở mục này");
        const r = ref(a.collection, id(a.id)),
          old = owned(value(await tx.get(r)), ownerId, "Bản ghi");
        const url = text(a.url, "URL ảnh");
        if (!url.startsWith("https://firebasestorage.googleapis.com/"))
          throw new Error("Ảnh phải được tải lên Firebase Storage");
        if ((old.imageUrls || []).length >= 12)
          throw new Error("Tối đa 12 ảnh");
        tx.update(r, {
          imageUrls: FieldValue.arrayUnion(url),
          updatedAt: stamp(),
        });
        return { id: a.id };
      }
      throw new Error("Thao tác không được hỗ trợ");
    });
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError(
      "failed-precondition",
      e.message || "Không thực hiện được",
    );
  }
});

// Chỉ người thuê được liên kết với hóa đơn mới có thể báo đã chuyển tiền.
exports.reportPayment = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Cần đăng nhập");
  const billId = id(req.data.id);
  return db.runTransaction(async (tx) => {
    const r = ref("invoices", billId),
      b = value(await tx.get(r));
    if (!b || b.recipientUid !== req.auth.uid)
      throw new HttpsError("permission-denied", "Không phải hóa đơn của bạn");
    if (b.status !== "unpaid")
      throw new HttpsError(
        "failed-precondition",
        "Hóa đơn không ở trạng thái chờ thanh toán",
      );
    tx.update(r, {
      status: "reported",
      reportedAt: stamp(),
      paymentNote: text(req.data.note, "ghi chú thanh toán", true),
      updatedAt: stamp(),
    });
    notify(
      tx,
      `reported_${billId}`,
      "Người thuê báo đã chuyển tiền",
      `${b.roomName} · ${b.period}. Cần kiểm tra giao dịch trước khi xác nhận.`,
      { ownerId: b.ownerId, invoiceId: billId },
    );
    return { ok: true };
  });
});

exports.tenantPortal = onCall({ timeoutSeconds: 30 }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Cần đăng nhập");
  if (req.auth.token.email_verified !== true)
    throw new HttpsError("permission-denied", "Hãy xác minh email trước.");
  const action = req.data?.action || "load",
    email = req.auth.token.email;

  if (action === "lookup") {
    if (typeof email !== "string" || !email.trim())
      throw new HttpsError(
        "failed-precondition",
        "Tài khoản đăng nhập chưa có email.",
      );
    const candidates = [...new Set([email.trim(), email.trim().toLowerCase()])];
    const snapshots = await Promise.all(
      candidates.map((candidate) =>
        db.collection("tenants").where("email", "==", candidate).get(),
      ),
    );
    const unique = new Map();
    for (const snapshot of snapshots)
      for (const doc of snapshot.docs)
        if (!doc.data().archived && doc.data().roomId)
          unique.set(doc.id, doc);
    return {
      profiles: [...unique.values()].map((doc) => ({
        id: doc.id,
        name: doc.data().name || "",
        email: doc.data().email || "",
        authUid: doc.data().authUid || "",
      })),
    };
  }

  if (action === "link") {
    if (typeof email !== "string" || !email.trim())
      throw new HttpsError(
        "failed-precondition",
        "Tài khoản đăng nhập chưa có email.",
      );
    const tenantId = id(req.data?.data?.tenantId);
    const tenantRef = ref("tenants", tenantId);
    let tenantName = "";
    try {
      await db.runTransaction(async (tx) => {
        const snapshot = await tx.get(tenantRef);
        const tenant = snapshot.data();
        if (
          !snapshot.exists ||
          !tenant ||
          typeof tenant.email !== "string" ||
          tenant.email.trim().toLowerCase() !== email.trim().toLowerCase() ||
          tenant.archived ||
          typeof tenant.roomId !== "string" ||
          !tenant.roomId
        )
          throw new HttpsError(
            "permission-denied",
            "Email không khớp hồ sơ thuê đang hoạt động. Hãy nhờ chủ trọ kiểm tra email và phòng.",
          );
        if (tenant.authUid && tenant.authUid !== uid)
          throw new HttpsError(
            "failed-precondition",
            "Hồ sơ thuê này đã liên kết với một tài khoản khác. Hãy liên hệ chủ trọ.",
          );
        tenantName = tenant.name || "";
        tx.update(tenantRef, { authUid: uid, updatedAt: stamp() });
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "failed-precondition",
        error.message || "Không liên kết được hồ sơ thuê.",
      );
    }
    return { tenantName };
  }

  if (action !== "load" && action !== "createMaintenance")
    throw new HttpsError("invalid-argument", "Thao tác không được hỗ trợ.");

  const profiles = await db
    .collection("tenants")
    .where("authUid", "==", uid)
    .get();
  const linked = profiles.docs.filter((doc) => !doc.data().archived);
  if (linked.length !== 1)
    throw new HttpsError(
      "failed-precondition",
      "Tài khoản cần được liên kết với đúng một hồ sơ thuê đang hoạt động.",
    );

  const profileDoc = linked[0],
    tenant = profileDoc.data(),
    ownerId = id(tenant.ownerId),
    roomId = id(tenant.roomId);
  const [roomSnap, settingsSnap] = await Promise.all([
    ref("rooms", roomId).get(),
    ref("settings", ownerId).get(),
  ]);
  const room = roomSnap.data();
  if (!room || room.ownerId !== ownerId || room.archived)
    throw new HttpsError(
      "failed-precondition",
      "Phòng thuê không còn hoạt động. Vui lòng liên hệ chủ trọ.",
    );

  if (action === "createMaintenance") {
    const data = req.data.data || {};
    const title = text(data.title, "tiêu đề yêu cầu");
    const description = text(data.description, "mô tả yêu cầu");
    const issueType = text(data.issueType, "loại sự cố");
    const priority = text(data.priority, "mức độ ưu tiên");
    if (!["Thiết bị", "Điện / Nước", "Nội thất", "Khác"].includes(issueType))
      throw new HttpsError("invalid-argument", "Loại sự cố không hợp lệ.");
    if (!["Thấp", "Trung bình", "Cao"].includes(priority))
      throw new HttpsError("invalid-argument", "Mức độ ưu tiên không hợp lệ.");

    const maintenanceRef = db.collection("maintenance").doc();
    await db.runTransaction(async (tx) => {
      const currentTenant = await tx.get(profileDoc.ref);
      const currentRoom = await tx.get(ref("rooms", roomId));
      const current = currentTenant.data(),
        currentRoomData = currentRoom.data();
      if (
        !currentTenant.exists ||
        current.authUid !== uid ||
        current.archived ||
        current.roomId !== roomId ||
        !currentRoom.exists ||
        currentRoomData.ownerId !== ownerId ||
        currentRoomData.archived
      )
        throw new HttpsError(
          "failed-precondition",
          "Hồ sơ thuê hoặc phòng không còn hoạt động.",
        );
      tx.create(maintenanceRef, {
        ownerId,
        roomId,
        tenantId: profileDoc.id,
        requesterUid: uid,
        roomName: room.name,
        tenantName: tenant.name || "",
        title,
        description,
        issueType,
        priority,
        status: "new",
        cost: 0,
        createdAt: stamp(),
        updatedAt: stamp(),
      });
      notify(
        tx,
        `tenant_maintenance_${maintenanceRef.id}`,
        "Yêu cầu bảo trì mới",
        `${room.name} · ${title}`,
        { ownerId, roomId },
      );
    });
    return { id: maintenanceRef.id };
  }

  const [contractsSnap, metersSnap, maintenanceSnap, invoicesSnap] =
    await Promise.all([
      db
        .collection("contracts")
        .where("ownerId", "==", ownerId)
        .where("roomId", "==", roomId)
        .get(),
      db
        .collection("meters")
        .where("ownerId", "==", ownerId)
        .where("roomId", "==", roomId)
        .get(),
      db
        .collection("maintenance")
        .where("ownerId", "==", ownerId)
        .where("roomId", "==", roomId)
        .get(),
      db
        .collection("invoices")
        .where("ownerId", "==", ownerId)
        .where("recipientUid", "==", uid)
        .get(),
    ]);

  const contracts = contractsSnap.docs
    .filter((doc) => {
      const contract = doc.data();
      return (
        contract.tenantId === profileDoc.id ||
        (Array.isArray(contract.tenantIds) &&
          contract.tenantIds.includes(profileDoc.id))
      );
    })
    .map((doc) =>
      tenantRecord(doc, [
        "number",
        "status",
        "roomName",
        "startDate",
        "endDate",
        "rent",
        "deposit",
        "paymentDay",
        "paymentTermDays",
        "note",
      ]),
    )
    .sort((a, b) => (b.startDate || "").localeCompare(a.startDate || ""));
  const serviceIds = [...new Set(room.serviceIds || [])].slice(0, 30);
  const serviceSnaps = serviceIds.length
    ? await db.getAll(...serviceIds.map((serviceId) => ref("services", id(serviceId))))
    : [];
  const services = serviceSnaps
    .filter((doc) => doc.exists && doc.data().ownerId === ownerId && !doc.data().archived)
    .map((doc) =>
      tenantRecord(doc, ["name", "mode", "price", "unit", "description"]),
    );
  const maintenance = maintenanceSnap.docs
    .filter(
      (doc) =>
        doc.data().tenantId === profileDoc.id ||
        doc.data().requesterUid === uid,
    )
    .map((doc) =>
      tenantRecord(doc, [
        "title",
        "description",
        "issueType",
        "priority",
        "status",
        "cost",
        "createdAt",
        "updatedAt",
      ]),
    )
    .sort((a, b) => (b.createdAt || "").localeCompare(a.createdAt || ""));

  return {
    tenant: {
      id: profileDoc.id,
      name: tenant.name || "",
      email: tenant.email || "",
      phone: tenant.phone || "",
      role: tenant.role || "",
      roomId,
    },
    room: {
      id: roomSnap.id,
      name: room.name || "",
      condition: room.condition || room.status || "",
      area: room.area ?? null,
      capacity: room.capacity ?? null,
      price: room.price ?? null,
      billingDay: room.billingDay || "",
      paymentTermDays: room.paymentTermDays ?? null,
      description: room.description || "",
    },
    landlord: {
      name: settingsSnap.data()?.name || "",
      phone: settingsSnap.data()?.phone || "",
      address: settingsSnap.data()?.address || "",
    },
    contracts,
    services,
    meters: metersSnap.docs
      .filter((doc) => serviceIds.includes(doc.data().serviceId))
      .map((doc) =>
        tenantRecord(doc, ["serviceId", "period", "previous", "current"]),
      ),
    maintenance,
    invoices: invoicesSnap.docs.map((doc) =>
      tenantRecord(doc, [
        "roomName",
        "period",
        "dueDate",
        "issueDate",
        "total",
        "status",
        "code",
      ]),
    ),
  };
});

function tenantRecord(doc, fields) {
  const data = doc.data();
  const record = { id: doc.id };
  for (const field of fields) {
    const value = data[field];
    if (value !== undefined) {
      record[field] =
        value && typeof value.toDate === "function"
          ? value.toDate().toISOString()
          : value;
    }
  }
  return record;
}

// Mỗi hợp đồng/kỳ chỉ có một ID hóa đơn. Transaction chống tạo trùng khi lịch và thao tác tay cùng chạy.
async function invoice(ownerId, roomId, p, commit) {
  id(roomId);
  const day = B.today();
  return db.runTransaction(async (tx) => {
    const room = owned(
      value(await tx.get(ref("rooms", roomId))),
      ownerId,
      "Phòng",
    );
    const cs = await tx.get(
      ownerQuery("contracts", ownerId, "roomId", roomId),
    );
    const contracts = cs.docs
      .map(value)
      .filter(
        (x) => x.status === "active" && x.startDate <= day && x.endDate >= day,
      );
    if (contracts.length !== 1)
      throw new Error(
        "Cần đúng một hợp đồng đang hiệu lực, liên kết phòng và người thuê",
      );
    const c = contracts[0],
      billId = B.invoiceId(c._id, p),
      billref = ref("invoices", billId);
    const prior = value(await tx.get(billref));
    if (prior) {
      owned(prior, ownerId, "Hóa đơn");
      if (commit) return { id: billId, existing: true };
      throw new Error(
        "Kỳ này đã có hóa đơn (kể cả đã hủy). Không tạo thêm hóa đơn trùng kỳ",
      );
    }
    if (p !== day.slice(0, 7))
      throw new Error(
        "Chỉ phát hành kỳ tháng hiện tại để tránh tính nhầm lịch sử",
      );
    const serviceIds = [...new Set(room.serviceIds || [])];
    const services = [];
    const meters = {};
    for (const sid of serviceIds) {
      const s = owned(
        value(await tx.get(ref("services", id(sid)))),
        ownerId,
        "Dịch vụ",
      );
      services.push(s);
      if (s.mode === "meter") {
        const meter = value(
          await tx.get(
            ref("meters", `${roomId}_${sid}_${B.previousPeriod(p)}`),
          ),
        );
        if (meter) owned(meter, ownerId, "Chỉ số");
        meters[sid] = meter;
      }
    }
    const xs = await tx.get(
      ownerQuery("extras", ownerId, "roomId", roomId),
    );
    const ts = await tx.get(
      ownerQuery("tenants", ownerId, "roomId", roomId),
    );
    const settings = value(await tx.get(ref("settings", ownerId))) || {};
    const t = owned(
      value(await tx.get(ref("tenants", c.tenantId))),
      ownerId,
      "Người thuê",
    );
    if (t.roomId !== roomId)
      throw new Error("Người đứng hợp đồng không còn thuộc phòng");
    const bill = B.buildInvoice({
      contract: {
        ...c,
        recipientUid: t.authUid || c.recipientUid || "",
        bank: {
          name: settings.bankName || "",
          account: settings.bankAccount || "",
          holder: settings.bankHolder || "",
        },
      },
      room: {
        ...room,
        people: ts.docs.filter((x) => !x.data().archived).length,
      },
      services,
      meters,
      extras: xs.docs.map(value).filter((x) => x.period === p),
      p,
      day,
    });
    bill.ownerId = ownerId;
    bill.code = `HD-${p.replace("-", "")}-${billId.slice(0, 8).toUpperCase()}`;
    if (commit) {
      tx.create(billref, { ...bill, createdAt: stamp(), updatedAt: stamp() });
      notify(
        tx,
        `issued_manager_${billId}`,
        "Đã phát hành hóa đơn",
        `${room.name} · ${p}${bill.recipientUid ? "" : " — chưa liên kết tài khoản người thuê"}`,
        { ownerId, invoiceId: billId },
      );
      if (bill.recipientUid)
        notify(
          tx,
          `issued_tenant_${billId}`,
          "Hóa đơn tiền phòng mới",
          `${room.name} · ${p}: ${bill.total.toLocaleString("vi-VN")}đ. Hạn ${bill.dueDate}`,
          {
            ownerId,
            audience: "tenant",
            recipientUid: bill.recipientUid,
            invoiceId: billId,
          },
        );
    }
    return { id: billId, ...bill, preview: !commit };
  });
}

async function runBilling(ownerId) {
  const day = B.today(),
    p = day.slice(0, 7);
  const config = (await ref("settings", ownerId).get()).data() || {};
  let created = 0,
    existing = 0,
    blocked = 0,
    late = 0;
  const cs = await db.collection("contracts").where("ownerId", "==", ownerId).get();
  for (const doc of cs.docs) {
    const c = doc.data();
    if (c.status === "scheduled" && c.startDate <= day && c.endDate >= day)
      await doc.ref.update({ status: "active", updatedAt: stamp() });
    if (active(c) && c.endDate < day) {
      await doc.ref.update({ status: "expired", updatedAt: stamp() });
      continue;
    }
    if (
      !["active", "scheduled"].includes(c.status) ||
      !c.roomId ||
      c.startDate > day ||
      c.endDate < day
    )
      continue;
    if (!config.autoBilling) continue;
    try {
      const roomData = (await ref("rooms", c.roomId).get()).data();
      if (!roomData || roomData.archived) continue;
      const r = owned(roomData, ownerId, "Phòng");
      const bday = parseInt(r.billingDay, 10);
      if (day < B.billingDate(p, bday)) continue;
      const result = await invoice(ownerId, c.roomId, p, true);
      result.existing ? existing++ : created++;
    } catch (e) {
      blocked++;
      const nref = ref(
        "notifications",
        `billing_blocked_${doc.id}_${p}`,
      );
      await db.runTransaction(async (tx) => {
        if ((await tx.get(nref)).exists) return;
        notify(
          tx,
          nref.id,
          "Chưa xuất được hóa đơn",
          `${c.roomName || c.roomId}: ${e.message}`,
          { ownerId, roomId: c.roomId },
        );
      });
    }
  }
  const bs = await db
    .collection("invoices")
    .where("ownerId", "==", ownerId)
    .where("status", "in", ["unpaid", "reported"])
    .get();
  for (const doc of bs.docs) {
    const b = doc.data();
    if (!b.dueDate || !B.lateAlert(b, day)) continue;
    const nref = ref("notifications", `overdue_${doc.id}`);
    const did = await db.runTransaction(async (tx) => {
      const [current, notice] = await Promise.all([
        tx.get(doc.ref),
        tx.get(nref),
      ]);
      if (notice.exists || !B.lateAlert(current.data(), day)) return false;
      notify(
        tx,
        nref.id,
        "Hóa đơn quá hạn hơn 5 ngày",
        `${b.roomName} · ${b.period}: ${b.total.toLocaleString("vi-VN")}đ`,
        { ownerId, invoiceId: doc.id },
      );
      return true;
    });
    if (did) late++;
  }
  return {
    created,
    existing,
    blocked,
    late,
    day,
    autoBilling: config.autoBilling === true,
  };
}
async function runScheduledBilling() {
  const managers = await db.collection("managers").where("enabled", "==", true).get();
  for (const managerDoc of managers.docs) await runBilling(managerDoc.id);
}
exports.billingHourly = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: "Asia/Ho_Chi_Minh",
    timeoutSeconds: 540,
    retryCount: 3,
  },
  runScheduledBilling,
);

// Thông báo trong app là dữ liệu chính; FCM gửi thêm tới thiết bị đã đăng ký token.
exports.pushNotification = onDocumentCreated(
  { document: "notifications/{noticeId}", retry: true },
  async (event) => {
    const n = event.data?.data();
    if (!n) return;
    const owners =
      n.audience === "tenant" ? [n.recipientUid] : [n.ownerId];
    let sent = 0;
    for (const uid of owners.filter(Boolean)) {
      const tokens = await db
        .collection("users")
        .doc(uid)
        .collection("tokens")
        .get();
      for (let offset = 0; offset < tokens.docs.length; offset += 500) {
        const docs = tokens.docs.slice(offset, offset + 500);
        if (!docs.length) continue;
        const response = await getMessaging().sendEachForMulticast({
          tokens: docs.map((x) => x.data().token),
          notification: { title: n.title, body: n.body },
          data: {
            noticeId: event.params.noticeId,
            invoiceId: n.invoiceId || "",
          },
          android: {
            priority: "high",
            notification: { tag: event.params.noticeId },
          },
        });
        sent += response.successCount;
        let retry = false;
        for (let i = 0; i < response.responses.length; i++) {
          const e = response.responses[i].error;
          if (!e) continue;
          if (
            [
              "messaging/registration-token-not-registered",
              "messaging/invalid-registration-token",
            ].includes(e.code)
          )
            await docs[i].ref.delete();
          else retry = true;
        }
        if (retry) throw new Error("FCM tạm thời chưa gửi được, cần thử lại");
      }
    }
    await event.data.ref.update({
      pushStatus: sent ? "sent" : "no-device",
      pushSentAt: stamp(),
      pushCount: sent,
    });
  },
);

async function migrateServiceIds(ownerId) {
  const services = await db
    .collection("services")
    .where("ownerId", "==", ownerId)
    .get();
  const needingId = services.docs.filter((doc) => doc.data().id !== doc.id);
  for (let offset = 0; offset < needingId.length; offset += 450) {
    const batch = db.batch();
    for (const doc of needingId.slice(offset, offset + 450))
      batch.update(doc.ref, { id: doc.id });
    await batch.commit();
  }
  return { ownerId, updated: needingId.length };
}

async function migrateOwnerData(ownerId) {
  const migrationRef = ref("system", "ownerMigration");
  await db.runTransaction(async (tx) => {
    const migration = await tx.get(migrationRef);
    if (migration.exists && migration.data().ownerId !== ownerId)
      throw new Error("Dữ liệu cũ đã được gán cho một tài khoản chủ trọ khác");
    if (!migration.exists)
      tx.create(migrationRef, {
        ownerId,
        startedAt: stamp(),
      });
  });

  const collections = [
    "rooms",
    "tenants",
    "services",
    "meters",
    "contracts",
    "extras",
    "maintenance",
    "invoices",
    "notifications",
  ];
  const migrated = {};
  for (const collection of collections) {
    const snapshot = await db.collection(collection).get();
    const unowned = snapshot.docs.filter((doc) => !doc.data().ownerId);
    migrated[collection] = unowned.length;
    for (let offset = 0; offset < unowned.length; offset += 450) {
      const batch = db.batch();
      for (const doc of unowned.slice(offset, offset + 450))
        batch.update(doc.ref, { ownerId });
      await batch.commit();
    }
  }

  migrated.serviceIds = (await migrateServiceIds(ownerId)).updated;

  const oldSettings = await ref("settings", "landlord").get();
  const newSettings = ref("settings", ownerId);
  await db.runTransaction(async (tx) => {
    const current = await tx.get(newSettings);
    if (!current.exists && oldSettings.exists)
      tx.create(newSettings, { ...oldSettings.data(), ownerId });
    else if (current.exists && !current.data().ownerId)
      tx.update(newSettings, { ownerId });
  });
  await migrationRef.update({ completedAt: stamp(), migrated });
  return { ownerId, migrated };
}

// Chạy dry-run trước; chỉ chuẩn hóa trường/quan hệ xác định được, giữ dữ liệu cũ.
async function migrateLegacy(ownerId, apply) {
  const [rs, ts, cs] = await Promise.all(
    ["rooms", "tenants", "contracts"].map((x) =>
      db.collection(x).where("ownerId", "==", ownerId).get(),
    ),
  );
  const rooms = rs.docs.map(value),
    tenants = ts.docs.map(value);
  const changes = [],
    warnings = [];
  const iso = (v) => {
    if (typeof v !== "string") return null;
    if (/^\d{4}-\d{2}-\d{2}$/.test(v)) {
      try {
        return B.date(v);
      } catch {
        return null;
      }
    }
    const p = v.split("/");
    if (p.length !== 3) return null;
    try {
      return B.date(
        `${p[2]}-${p[1].padStart(2, "0")}-${p[0].padStart(2, "0")}`,
      );
    } catch {
      return null;
    }
  };
  for (const r of rooms) {
    const condition =
      r.condition || (["Đang sửa"].includes(r.status) ? "Đang sửa" : "Tốt");
    const patch = {
      condition,
      status: condition,
      archived: r.archived || false,
      capacity: r.capacity || Math.max(4, Number(r.people) || 0),
      serviceIds: r.serviceIds || [],
      paymentTermDays: r.paymentTermDays ?? 5,
      zone: FieldValue.delete(),
    };
    for (const f of ["price", "deposit", "area"])
      try {
        patch[f] = B.finite(r[f], f, { min: f === "deposit" ? 0 : 0.1 });
      } catch {
        warnings.push(`rooms/${r._id}: cần nhập ${f}`);
      }
    changes.push({
      collection: "rooms",
      id: r._id,
      fields: Object.keys(patch),
    });
    if (apply)
      await ref("rooms", r._id).set(
        { ...patch, ownerId, updatedAt: stamp() },
        { merge: true },
      );
  }
  for (const t of tenants) {
    if (t.roomId) continue;
    const room = rooms.filter(
      (r) => r.name === t.room || r.name === t.roomName,
    );
    if (room.length !== 1) {
      warnings.push(`tenants/${t._id}: chọn lại phòng trong app`);
      continue;
    }
    if (apply)
      await ref("tenants", t._id).set(
        { ownerId, roomId: room[0]._id, archived: false },
        { merge: true },
      );
    changes.push({
      collection: "tenants",
      id: t._id,
      fields: ["roomId", "archived"],
    });
  }
  for (const c of cs.docs.map(value)) {
    if (c.roomId && c.tenantId && c.startDate && c.number) continue;
    const room = rooms.filter(
        (r) => r._id === c.roomId || r.name === c.room || r.name === c.roomName,
      ),
      tenant = tenants.filter(
        (t) =>
          t._id === c.tenantId ||
          (c.identity && t.identity === c.identity) ||
          (c.email && t.email === c.email),
      );
    const start = iso(c.startDate || c.start),
      end = iso(c.endDate || c.end);
    if (room.length !== 1 || tenant.length !== 1 || !start || !end) {
      warnings.push(
        `contracts/${c._id}: thiếu liên kết/ngày; mở chi tiết hợp đồng để kiểm tra hoặc tạo hợp đồng chuẩn mới`,
      );
      continue;
    }
    const patch = {
      number: c.number || c.id || `HD-${c._id}`,
      roomId: room[0]._id,
      roomName: room[0].name,
      tenantId: tenant[0]._id,
      tenantName: tenant[0].name,
      startDate: start,
      endDate: end,
      status: ["Đã thanh lý", "ended", "cancelled"].includes(c.status)
        ? "ended"
        : end < B.today()
          ? "expired"
          : start > B.today()
            ? "scheduled"
            : "active",
      rent: Number(c.rent),
      deposit: Number(c.deposit),
      recipientUid: tenant[0].authUid || "",
      ownerId,
    };
    if (
      !Number.isFinite(patch.rent) ||
      patch.rent <= 0 ||
      !Number.isFinite(patch.deposit)
    ) {
      warnings.push(`contracts/${c._id}: tiền thuê/cọc sai kiểu`);
      continue;
    }
    changes.push({
      collection: "contracts",
      id: c._id,
      fields: Object.keys(patch),
    });
    if (apply) await ref("contracts", c._id).set(patch, { merge: true });
  }
  if (apply) {
    const all = await db.collection("tenants").where("ownerId", "==", ownerId).get();
    for (const r of rooms)
      await ref("rooms", r._id).update({
        people: all.docs.filter(
          (t) => !t.data().archived && t.data().roomId === r._id,
        ).length,
      });
  }
  return { apply, changes, warnings };
}
