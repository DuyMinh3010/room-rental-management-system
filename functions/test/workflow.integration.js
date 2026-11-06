const { test, before } = require("node:test");
const assert = require("node:assert/strict");
process.env.GCLOUD_PROJECT = "demo-rrms";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
const functions = require("../index");
const { getFirestore } = require("firebase-admin/firestore");
const B = require("../billing");
const db = getFirestore();
const call = (action, args = {}, uid = "owner") =>
  functions.manage.run({ auth: { uid, token: {} }, data: { action, ...args } });
before(async () => {
  await db.doc("managers/owner").set({ enabled: true });
});
test("callable từ chối tài khoản ngoài managers", async () => {
  await assert.rejects(
    () => call("saveRoom", { data: {} }, "stranger"),
    /chưa được cấp quyền/,
  );
});
test("tạo phòng, dịch vụ, chỉ số, người thuê, hợp đồng và hóa đơn thật trong emulator", async () => {
  await call("saveRoom", {
    id: "workflow-room",
    data: {
      name: "TEST WORKFLOW",
      condition: "Tốt",
      capacity: 4,
      area: 25,
      price: 3500000,
      deposit: 3500000,
      billingDay: 5,
      paymentTermDays: 5,
      description: "Test",
    },
  });
  await call("saveTenant", {
    id: "workflow-tenant",
    data: { name: "Test User", phone: "0900000000", roomId: "workflow-room" },
  });
  await call("saveService", {
    id: "workflow-electric",
    data: { name: "Điện test", mode: "meter", price: 3500, unit: "kWh" },
  });
  await call("assignServices", {
    roomId: "workflow-room",
    serviceIds: ["workflow-electric"],
  });
  await call("saveContract", {
    id: "workflow-contract",
    data: {
      number: "TEST-HD-01",
      roomId: "workflow-room",
      tenantId: "workflow-tenant",
      startDate: "2026-01-01",
      endDate: "2099-12-31",
    },
  });
  assert.equal((await db.doc("rooms/workflow-room").get()).data().ownerId, "owner");
  assert.equal(
    (await db.doc("tenants/workflow-tenant").get()).data().ownerId,
    "owner",
  );
  assert.equal(
    (await db.doc("contracts/workflow-contract").get()).data().ownerId,
    "owner",
  );
  await db.doc("managers/other-owner").set({ enabled: true });
  await assert.rejects(
    () => call("archiveRoom", { id: "workflow-room" }, "other-owner"),
    /không thuộc tài khoản chủ trọ này/,
  );
  await assert.rejects(
    () =>
      call("issueInvoice", {
        roomId: "workflow-room",
        period: B.today().slice(0, 7),
      }),
    /Thiếu chỉ số/,
  );
  await call("saveMeter", {
    data: {
      roomId: "workflow-room",
      serviceId: "workflow-electric",
      period: B.previousPeriod(B.today().slice(0, 7)),
      previous: 100,
      current: 120,
    },
  });
  const p = B.today().slice(0, 7);
  await call("saveExtra", {
    id: "workflow-extra",
    data: {
      roomId: "workflow-room",
      period: p,
      reason: "Thay khóa",
      amount: 50000,
    },
  });
  const preview = await call("previewInvoice", {
    roomId: "workflow-room",
    period: p,
  });
  assert.equal(preview.total, 3620000);
  const results = await Promise.all([
    call("issueInvoice", { roomId: "workflow-room", period: p }),
    call("issueInvoice", { roomId: "workflow-room", period: p }),
  ]);
  assert.equal(results[0].id, results[1].id);
  assert.equal(results.filter((x) => x.existing).length, 1);
  const bills = await db
    .collection("invoices")
    .where("roomId", "==", "workflow-room")
    .get();
  assert.equal(bills.size, 1);
  assert.equal(bills.docs[0].data().total, 3620000);
  assert.equal(bills.docs[0].data().ownerId, "owner");
  await assert.rejects(
    () =>
      call("saveMeter", {
        data: {
          roomId: "workflow-room",
          serviceId: "workflow-electric",
          period: B.previousPeriod(p),
          previous: 100,
          current: 130,
        },
      }),
    /đã phát hành/,
  );
  await assert.rejects(
    () => call("archiveRoom", { id: "workflow-room" }),
    /Cần chuyển người thuê/,
  );
  await call("confirmPayment", { id: results[0].id, method: "bank" });
  assert.equal((await bills.docs[0].ref.get()).data().status, "paid");
  assert.equal(
    (await db.doc(`notifications/paid_manager_${results[0].id}`).get()).exists,
    true,
  );
  await assert.rejects(
    () => call("confirmPayment", { id: results[0].id, method: "bank" }),
    /đã thanh toán/,
  );
});
test("hai thao tác cùng thêm tên phòng chỉ một thao tác thành công", async () => {
  const data = {
    name: "TEST UNIQUE ROOM",
    condition: "Tốt",
    capacity: 4,
    area: 20,
    price: 2000000,
    deposit: 0,
    billingDay: 5,
    paymentTermDays: 5,
  };
  const results = await Promise.allSettled([
    call("saveRoom", { id: "unique1", data }),
    call("saveRoom", { id: "unique2", data }),
  ]);
  assert.equal(results.filter((x) => x.status === "fulfilled").length, 1);
});
test("hợp đồng chốt giá từ phòng, không lấy giá thuê do client gửi", async () => {
  const c = (await db.doc("contracts/workflow-contract").get()).data();
  assert.equal(c.rent, 3500000);
  assert.equal(c.deposit, 3500000);
  await call("saveRoom", {
    id: "workflow-room",
    data: {
      name: "TEST WORKFLOW",
      condition: "Tốt",
      capacity: 4,
      area: 25,
      price: 4000000,
      deposit: 4000000,
      billingDay: 5,
      paymentTermDays: 5,
    },
  });
  assert.equal(
    (await db.doc("contracts/workflow-contract").get()).data().rent,
    3500000,
  );
});
test("nhắc quá hạn hơn 5 ngày một lần, tenant không tự đánh dấu paid", async () => {
  await db
    .doc("invoices/test-overdue")
    .set({
      ownerId: "owner",
      roomId: "workflow-room",
      roomName: "TEST WORKFLOW",
      period: "2026-01",
      dueDate: B.addDays(B.today(), -6),
      status: "unpaid",
      total: 100000,
      recipientUid: "tenant",
    });
  await db.doc("settings/owner").set({
    ownerId: "owner",
    autoBilling: false,
  });
  await call("runBilling");
  await call("runBilling");
  assert.equal(
    (await db.doc("notifications/overdue_test-overdue").get()).exists,
    true,
  );
  await assert.rejects(
    () =>
      functions.reportPayment.run({
        auth: { uid: "other" },
        data: { id: "test-overdue" },
      }),
    /Không phải hóa đơn/,
  );
  await functions.reportPayment.run({
    auth: { uid: "tenant" },
    data: { id: "test-overdue", note: "Đã chuyển" },
  });
  assert.equal(
    (await db.doc("invoices/test-overdue").get()).data().status,
    "reported",
  );
  assert.equal(
    (await db.doc("notifications/reported_test-overdue").get()).exists,
    true,
  );
});

test('không xóa dịch vụ đang áp dụng hoặc lập hợp đồng trùng thời hạn', async () => {
  await assert.rejects(() => call('archiveService', {id:'workflow-electric'}), /Bỏ áp dụng/);
  await assert.rejects(() => call('saveContract', {id:'overlapping',data:{number:'TEST-HD-02',roomId:'workflow-room',tenantId:'workflow-tenant',startDate:'2026-01-01',endDate:'2099-12-31'}}), /trùng thời hạn/);
});
test('gửi lại sau khi liên kết tài khoản tạo hộp thư cho đúng UID',async()=>{
  const bill=(await db.collection('invoices').where('contractId','==','workflow-contract').get()).docs[0];
  await assert.rejects(()=>call('resendInvoice',{id:bill.id}),/Liên kết tài khoản/);
  await db.doc('tenants/workflow-tenant').update({authUid:'linked-tenant'});
  await call('resendInvoice',{id:bill.id});
  assert.equal((await bill.ref.get()).data().recipientUid,'linked-tenant');
  assert.equal((await db.doc(`notifications/resent_${bill.id}_1`).get()).data().recipientUid,'linked-tenant');
});
test('chỉ số tháng sau tự lấy số mới tháng trước và bảo vệ chuỗi lịch sử',async()=>{
  await call('saveRoom',{id:'meter-chain-room',data:{name:'TEST METER CHAIN',condition:'Tốt',capacity:4,area:20,price:2000000,deposit:0,billingDay:5,paymentTermDays:5}});
  await call('assignServices',{roomId:'meter-chain-room',serviceIds:['workflow-electric']});
  const p=B.previousPeriod(B.today().slice(0,7)),currentPeriod=B.today().slice(0,7);
  await call('saveMeter',{data:{roomId:'meter-chain-room',serviceId:'workflow-electric',period:p,previous:10,current:20}});
  await call('saveMeter',{data:{roomId:'meter-chain-room',serviceId:'workflow-electric',period:currentPeriod,previous:999,current:25}});
  const row=await db.doc(`meters/meter-chain-room_workflow-electric_${currentPeriod}`).get();assert.equal(row.data().previous,20);assert.equal(row.data().usage,5);
  await assert.rejects(()=>call('saveMeter',{data:{roomId:'meter-chain-room',serviceId:'workflow-electric',period:p,previous:10,current:22}}),/Kỳ sau/);
});
