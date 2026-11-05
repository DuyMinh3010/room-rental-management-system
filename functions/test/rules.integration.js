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
} = require("firebase/firestore");
let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-rrms",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("../firebase/firestore.rules", "utf8"),
    },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "managers", "owner"), { enabled: true });
    await setDoc(doc(db, "rooms", "r1"), { name: "P.101" });
    await setDoc(doc(db, "invoices", "b1"), {
      recipientUid: "tenant",
      status: "unpaid",
    });
    await setDoc(doc(db, "notifications", "n1"), {
      audience: "tenant",
      recipientUid: "tenant",
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
test("người thuê đọc hóa đơn của mình bằng query ràng buộc UID", async () => {
  const db = env.authenticatedContext("tenant").firestore();
  await assertSucceeds(
    getDocs(
      query(collection(db, "invoices"), where("recipientUid", "==", "tenant")),
    ),
  );
  await assertFails(getDocs(collection(db, "invoices")));
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

test('query thông báo của tenant đúng quyền, không đọc hộp thư người khác',async()=>{
 const db=env.authenticatedContext('tenant').firestore();
 await assertSucceeds(getDocs(query(collection(db,'notifications'),where('recipientUid','==','tenant'))));
 await assertFails(getDoc(doc(env.authenticatedContext('other').firestore(),'notifications','n1')));
});
