const { test } = require("node:test");
const assert = require("node:assert/strict");
const b = require("../billing");
const base = () => ({
  contract: {
    _id: "c1",
    roomId: "r1",
    tenantId: "t1",
    tenantName: "A",
    number: "HD01",
    status: "active",
    rent: 3500000,
    startDate: "2026-01-01",
    endDate: "2027-12-31",
  },
  room: { name: "P.101", people: 2, paymentTermDays: 5 },
  services: [],
  meters: {},
  extras: [],
  p: "2026-10",
  day: "2026-10-05",
});
test("lấy tiền phòng từ hợp đồng, cộng đúng điện/nước/người/phòng/phụ phí", () => {
  let x = base();
  x.services = [
    { _id: "e", name: "Điện", mode: "meter", unit: "kWh", price: 3500 },
    { _id: "w", name: "Nước", mode: "meter", unit: "m3", price: 20000 },
    { _id: "wifi", name: "WiFi", mode: "room", unit: "tháng", price: 100000 },
    { _id: "trash", name: "Rác", mode: "person", unit: "người", price: 20000 },
  ];
  x.meters = {
    e: { period: "2026-09", previous: 100, current: 120 },
    w: { period: "2026-09", previous: 20, current: 25 },
  };
  x.extras = [{ reason: "Thay khóa theo yêu cầu", amount: 50000 }];
  let bill = b.buildInvoice(x);
  assert.equal(bill.total, 3860000);
  assert.equal(bill.dueDate, "2026-10-10");
  assert.equal(bill.delivered, false);
});
test("không xuất hóa đơn nếu thiếu chỉ số", () => {
  let x = base();
  x.services = [
    { _id: "e", name: "Điện", price: 3500, mode: "meter", unit: "kWh" },
  ];
  assert.throws(() => b.buildInvoice(x), /Thiếu chỉ số/);
});
test("không cho chỉ số giảm, giá âm hoặc phụ phí không lý do", () => {
  let x = base();
  x.services = [
    { _id: "e", name: "Điện", price: 3500, mode: "meter", unit: "kWh" },
  ];
  x.meters = { e: { period: "2026-09", previous: 120, current: 100 } };
  assert.throws(() => b.buildInvoice(x), /nhỏ hơn/);
  x = base();
  x.contract.rent = -1;
  assert.throws(() => b.buildInvoice(x));
  x = base();
  x.extras = [{ reason: "", amount: 5 }];
  assert.throws(() => b.buildInvoice(x), /lý do/);
});
test("quá đúng 5 ngày chưa nhắc, ngày thứ 6 nhắc, đã trả/hủy không nhắc", () => {
  let x = { dueDate: "2026-10-10", status: "unpaid" };
  assert.equal(b.lateAlert(x, "2026-10-15"), false);
  assert.equal(b.lateAlert(x, "2026-10-16"), true);
  assert.equal(b.lateAlert({ ...x, status: "paid" }, "2026-10-20"), false);
  assert.equal(b.lateAlert({ ...x, status: "void" }, "2026-10-20"), false);
});
test("ngày 31 cuối tháng, năm nhuận, chuyển năm và múi giờ VN", () => {
  assert.equal(b.billingDate("2026-02", 31), "2026-02-28");
  assert.equal(b.billingDate("2028-02", 31), "2028-02-29");
  assert.equal(b.previousPeriod("2026-01"), "2025-12");
  assert.equal(b.today(new Date("2026-10-15T18:00:00Z")), "2026-10-16");
  assert.throws(() => b.date("2026-02-31"));
});
test("định danh một hóa đơn/hợp đồng/kỳ, hợp đồng ngoài hạn bị chặn", () => {
  assert.equal(b.invoiceId("c1", "2026-10"), b.invoiceId("c1", "2026-10"));
  let x = base();
  x.contract.endDate = "2026-09-30";
  assert.throws(() => b.buildInvoice(x), /ngoài thời hạn/);
});
