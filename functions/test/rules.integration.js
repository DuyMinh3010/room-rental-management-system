// Chạy riêng bằng Emulator, không gọi production: xem docs/KIEM_THU.md.
const { test, before, after } = require("node:test");
const fs = require("node:fs");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  setDoc,
  getDoc,
  collection,
  query,
  where,
  getDocs,
  updateDoc,
  serverTimestamp,
  runTransaction,
} = require("firebase/firestore");
let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-rrms",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("../firestore.rules", "utf8"),
    },
  });
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "managers", "owner"), { enabled: true });
    await setDoc(doc(db, "rooms", "r1"), {
      ownerId: "owner",
      name: "P.101",
      serviceIds: ["s1"],
    });
    await setDoc(doc(db, "invoices", "b1"), {
      ownerId: "owner",
      tenantId: "linked-profile",
      recipientUid: "tenant",
      status: "unpaid",
    });
    await setDoc(doc(db, "tenants", "linked-profile"), {
      ownerId: "owner",
      email: "linked@example.com",
      roomId: "r1",
      archived: false,
      authUid: "tenant",
    });
    await setDoc(doc(db, "tenants", "mapping-recovery-profile"), {
      ownerId: "owner",
      email: "recovery@example.com",
      roomId: "r1",
      archived: false,
      authUid: "mapping-recovery-user",
    });
    await setDoc(doc(db, "notifications", "n1"), {
      ownerId: "owner",
      audience: "tenant",
      recipientUid: "tenant",
    });
    await setDoc(doc(db, "tenants", "tenant-profile"), {
      ownerId: "owner",
      email: "tenant@example.com",
      roomId: "r1",
      archived: false,
      authUid: "",
    });
    await setDoc(doc(db, "invoices", "tenant-old-invoice"), {
      ownerId: "owner",
      tenantId: "tenant-profile",
      recipientUid: "",
      delivered: false,
      status: "unpaid",
    });
    await setDoc(doc(db, "rooms", "r2"), {
      ownerId: "other-owner",
      name: "P.202",
    });
    await setDoc(doc(db, "services", "s1"), {
      ownerId: "owner",
      name: "Điện",
    });
    await setDoc(doc(db, "services", "other-service"), {
      ownerId: "other-owner",
      name: "Nước",
    });
    await setDoc(doc(db, "contracts", "c1"), {
      ownerId: "owner",
      roomId: "r1",
      tenantId: "tenant-profile",
      rent: 100,
    });
    await setDoc(doc(db, "contracts", "group-contract"), {
      ownerId: "owner",
      roomId: "r1",
      tenantIds: ["tenant-profile"],
      rent: 100,
    });
    await setDoc(doc(db, "contracts", "other-contract"), {
      ownerId: "other-owner",
      roomId: "r2",
      tenantId: "tenant-profile",
      rent: 100,
    });
    await setDoc(doc(db, "meters", "m1"), {
      ownerId: "owner",
      roomId: "r1",
      serviceId: "s1",
      period: "2025-01",
    });
    await setDoc(doc(db, "maintenance", "m1"), {
      ownerId: "owner",
      roomId: "r1",
      tenantId: "tenant-profile",
      title: "Sự cố",
    });
  });
});
after(async () => env?.cleanup());
test("khách không đọc phòng, quản lý đọc được", async () => {
  await assertFails(
    getDoc(doc(env.unauthenticatedContext().firestore(), "rooms", "r1")),
  );
  await assertSucceeds(
    getDoc(doc(env.authenticatedContext("owner").firestore(), "rooms", "r1")),
  );
  await assertFails(
    getDoc(doc(env.authenticatedContext("owner").firestore(), "rooms", "r2")),
  );
});

test("người thuê không đọc phòng/người khác và không tự nâng quyền", async () => {
  const db = env.authenticatedContext("tenant").firestore();
  await assertFails(getDoc(doc(db, "rooms", "r1")));
  await assertFails(setDoc(doc(db, "managers", "tenant"), { enabled: true }));
  await assertFails(
    getDoc(
      doc(env.authenticatedContext("other").firestore(), "invoices", "b1"),
    ),
  );
});
test("người thuê chỉ đọc được hóa đơn đã gửi tới UID của mình", async () => {
  const db = env.authenticatedContext("tenant").firestore();
  await assertSucceeds(getDoc(doc(db, "invoices", "b1")));
  await assertSucceeds(
    getDocs(
      query(collection(db, "invoices"), where("recipientUid", "==", "tenant")),
    ),
  );
  await assertFails(getDocs(collection(db, "invoices")));
});
test("dịch vụ yêu cầu id riêng khớp document ID và ownerId của chủ trọ", async () => {
  const db = env.authenticatedContext("owner").firestore();
  await assertSucceeds(
    setDoc(doc(db, "services", "new-service"), {
      id: "new-service",
      ownerId: "owner",
      mode: "room",
      name: "Vệ sinh",
      price: 50000,
    }),
  );
  await assertFails(
    setDoc(doc(db, "services", "wrong-service"), {
      id: "different-id",
      ownerId: "owner",
      mode: "room",
      name: "Dịch vụ sai ID",
      price: 50000,
    }),
  );
});
test("người thuê đã liên kết có thể khôi phục mapping còn thiếu", async () => {
  const tenantDb = env
    .authenticatedContext("mapping-recovery-user", {
      email: "recovery@example.com",
      email_verified: true,
    })
    .firestore();
  await assertSucceeds(
    setDoc(doc(tenantDb, "users", "mapping-recovery-user"), {
      tenantId: "mapping-recovery-profile",
      ownerId: "owner",
      roomId: "r1",
    }),
  );

  const otherDb = env
    .authenticatedContext("mapping-recovery-attacker", {
      email: "recovery@example.com",
      email_verified: true,
    })
    .firestore();
  await assertFails(
    setDoc(doc(otherDb, "users", "mapping-recovery-attacker"), {
      tenantId: "mapping-recovery-profile",
      ownerId: "owner",
      roomId: "r1",
    }),
  );
});
test("người thuê đã xác minh email chỉ tự liên kết hồ sơ và hóa đơn khớp", async () => {
  const db = env
    .authenticatedContext("tenant-email", {
      email: "tenant@example.com",
      email_verified: true,
    })
    .firestore();
  const profile = doc(db, "tenants", "tenant-profile");
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "tenants"),
        where("email", "==", "tenant@example.com"),
      ),
    ),
  );
  await assertFails(
    updateDoc(profile, {
      authUid: "tenant-email",
      updatedAt: serverTimestamp(),
    }),
  );
  await runTransaction(db, async (transaction) => {
    transaction.update(profile, {
      authUid: "tenant-email",
      updatedAt: serverTimestamp(),
    });
    transaction.set(doc(db, "users", "tenant-email"), {
      tenantId: "tenant-profile",
      ownerId: "owner",
      roomId: "r1",
    });
  });
  await assertFails(
    updateDoc(doc(db, "invoices", "tenant-old-invoice"), {
      recipientUid: "tenant-email",
      delivered: true,
      updatedAt: serverTimestamp(),
    }),
  );
  const ownerDb = env.authenticatedContext("owner").firestore();
  await assertSucceeds(
    updateDoc(doc(ownerDb, "invoices", "tenant-old-invoice"), {
      recipientUid: "tenant-email",
      delivered: true,
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "invoices"),
        where("recipientUid", "==", "tenant-email"),
      ),
    ),
  );
});

test("người thuê chỉ đọc dữ liệu phòng đã liên kết và có thể tạo yêu cầu bảo trì", async () => {
  const db = env
    .authenticatedContext("tenant-email", {
      email: "tenant@example.com",
      email_verified: true,
    })
    .firestore();
  await runTransaction(db, async (transaction) => {
    transaction.update(doc(db, "tenants", "tenant-profile"), {
      authUid: "tenant-email",
      updatedAt: serverTimestamp(),
    });
    transaction.set(doc(db, "users", "tenant-email"), {
      tenantId: "tenant-profile",
      ownerId: "owner",
      roomId: "r1",
    });
  });

  await assertSucceeds(getDoc(doc(db, "rooms", "r1")));
  await assertSucceeds(getDoc(doc(db, "services", "s1")));
  await assertFails(getDoc(doc(db, "services", "other-service")));
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "contracts"),
        where("ownerId", "==", "owner"),
        where("roomId", "==", "r1"),
        where("tenantId", "==", "tenant-profile"),
      ),
    ),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "contracts"),
        where("ownerId", "==", "owner"),
        where("roomId", "==", "r1"),
        where("tenantIds", "array-contains", "tenant-profile"),
      ),
    ),
  );
  await assertFails(getDoc(doc(db, "contracts", "other-contract")));
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "meters"),
        where("ownerId", "==", "owner"),
        where("roomId", "==", "r1"),
        where("serviceId", "==", "s1"),
      ),
    ),
  );
  await assertFails(
    getDocs(
      query(
        collection(db, "meters"),
        where("ownerId", "==", "owner"),
        where("roomId", "==", "r1"),
      ),
    ),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "maintenance"),
        where("ownerId", "==", "owner"),
        where("roomId", "==", "r1"),
        where("tenantId", "==", "tenant-profile"),
      ),
    ),
  );
  await assertFails(
    getDocs(
      query(
        collection(db, "maintenance"),
        where("ownerId", "==", "owner"),
        where("roomId", "==", "r1"),
      ),
    ),
  );
  await assertSucceeds(
    setDoc(doc(db, "maintenance", "tenant-request"), {
      ownerId: "owner",
      roomId: "r1",
      tenantId: "tenant-profile",
      requesterUid: "tenant-email",
      roomName: "P.101",
      tenantName: "Tenant",
      title: "Đèn hỏng",
      description: "Đèn phòng bị hỏng",
      issueType: "Thiết bị",
      priority: "Trung bình",
      status: "new",
      cost: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(db, "maintenance", "other-request"), {
      ownerId: "other-owner",
      roomId: "r2",
      tenantId: "tenant-profile",
      requesterUid: "tenant-email",
      title: "Yêu cầu ngoài phòng",
      description: "Không hợp lệ",
      issueType: "Khác",
      priority: "Thấp",
      status: "new",
      cost: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});
test("email chưa xác minh hoặc email khác không thể liên kết hồ sơ", async () => {
  const unverified = env
    .authenticatedContext("unverified", {
      email: "tenant@example.com",
      email_verified: false,
    })
    .firestore();
  const other = env
    .authenticatedContext("other-email", {
      email: "other@example.com",
      email_verified: true,
    })
    .firestore();
  await assertFails(
    getDocs(
      query(
        collection(unverified, "tenants"),
        where("email", "==", "tenant@example.com"),
      ),
    ),
  );
  await assertFails(
    getDocs(
      query(
        collection(other, "tenants"),
        where("email", "==", "tenant@example.com"),
      ),
    ),
  );
  await assertFails(
    updateDoc(doc(other, "tenants", "tenant-profile"), {
      authUid: "other-email",
      updatedAt: serverTimestamp(),
    }),
  );
});
test("kể cả quản lý cũng không ghi trực tiếp tiền/trạng thái hóa đơn", async () => {
  for (const uid of ["owner", "tenant"])
    await assertFails(
      setDoc(doc(env.authenticatedContext(uid).firestore(), "invoices", "b1"), {
        status: "paid",
        total: 0,
      }),
    );
});

test("query thông báo của tenant đúng quyền, không đọc hộp thư người khác", async () => {
  const db = env.authenticatedContext("tenant").firestore();
  await assertSucceeds(
    getDocs(
      query(
        collection(db, "notifications"),
        where("recipientUid", "==", "tenant"),
      ),
    ),
  );
  await assertFails(
    getDoc(
      doc(env.authenticatedContext("other").firestore(), "notifications", "n1"),
    ),
  );
});
