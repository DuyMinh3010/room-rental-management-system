"use strict";
const DAY = 86400000;
function fail(message) {
  throw new Error(message);
}
function finite(value, label, { min = 0, integer = false } = {}) {
  if (value === null || value === "" || value === undefined)
    fail(`Thiếu ${label}`);
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n) || n < min || (integer && !Number.isSafeInteger(n)))
    fail(`${label} không hợp lệ`);
  return n;
}
function date(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value))
    fail("Ngày phải có dạng YYYY-MM-DD");
  const d = new Date(value + "T00:00:00Z");
  if (!Number.isFinite(+d) || d.toISOString().slice(0, 10) !== value)
    fail("Ngày không tồn tại");
  return value;
}
function today(now = new Date()) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Ho_Chi_Minh",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(now);
  const p = Object.fromEntries(parts.map((x) => [x.type, x.value]));
  return `${p.year}-${p.month}-${p.day}`;
}
function period(value) {
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(value || ""))
    fail("Kỳ phải có dạng YYYY-MM");
  return value;
}
function previousPeriod(value) {
  period(value);
  const [y, m] = value.split("-").map(Number);
  return new Date(Date.UTC(y, m - 2, 1)).toISOString().slice(0, 7);
}
function nextPeriod(value) {
  period(value);
  const [y, m] = value.split("-").map(Number);
  return new Date(Date.UTC(y, m, 1)).toISOString().slice(0, 7);
}
function billingDate(p, day) {
  period(p);
  const [y, m] = p.split("-").map(Number);
  const d = finite(day, "ngày chốt", { min: 1, integer: true });
  if (d > 31) fail("Ngày chốt tối đa 31");
  return `${p}-${String(Math.min(d, new Date(Date.UTC(y, m, 0)).getUTCDate())).padStart(2, "0")}`;
}
function addDays(d, n) {
  date(d);
  return new Date(Date.parse(d + "T00:00:00Z") + n * DAY)
    .toISOString()
    .slice(0, 10);
}
function overdueDays(due, day) {
  date(due);
  date(day);
  return Math.max(0, Math.floor((Date.parse(day) - Date.parse(due)) / DAY));
}
function lateAlert(invoice, day) {
  return (
    ["unpaid", "reported"].includes(invoice.status) &&
    overdueDays(invoice.dueDate, day) > 5
  );
}
function invoiceId(contractId, p) {
  period(p);
  return `${contractId}_${p}`;
}
function buildInvoice({ contract, room, services, meters, extras, p, day }) {
  period(p);
  date(day);
  if (contract.status !== "active") fail("Hợp đồng chưa có hiệu lực");
  if (contract.startDate > day || contract.endDate < day)
    fail("Hợp đồng ngoài thời hạn");
  if (!contract.roomId || !contract.tenantId)
    fail("Hợp đồng chưa liên kết phòng/người thuê");
  const rent = finite(contract.rent, "giá thuê hợp đồng", {
    min: 1,
    integer: true,
  });
  const count = finite(room.people, "số người trong phòng", { integer: true });
  const meterPeriod = previousPeriod(p);
  const lines = [
    {
      name: `Tiền phòng ${p}`,
      quantity: 1,
      unitPrice: rent,
      amount: rent,
      type: "rent",
    },
  ];
  for (const s of services) {
    if (s.archived) fail(`Dịch vụ ${s.name} đã ngừng sử dụng`);
    const price = finite(s.price, `đơn giá ${s.name}`, { integer: true });
    let quantity;
    if (s.mode === "meter") {
      const m = meters[s._id];
      if (!m || m.period !== meterPeriod)
        fail(`Thiếu chỉ số ${s.name} kỳ ${meterPeriod}`);
      const old = finite(m.previous, "chỉ số cũ"),
        current = finite(m.current, "chỉ số mới");
      if (current < old) fail(`Chỉ số ${s.name} mới nhỏ hơn cũ`);
      quantity = Number((current - old).toFixed(3));
    } else if (s.mode === "room") quantity = 1;
    else if (s.mode === "person") quantity = count;
    else fail(`Cách tính ${s.name} không hợp lệ`);
    const amount = Math.round(quantity * price);
    lines.push({
      name: s.name,
      serviceId: s._id,
      quantity,
      unit: s.unit,
      unitPrice: price,
      amount,
      type: "service",
      meterPeriod: s.mode === "meter" ? meterPeriod : null,
    });
  }
  for (const x of extras) {
    if (typeof x.reason !== "string" || !x.reason.trim())
      fail("Phụ phí phải ghi rõ lý do");
    lines.push({
      name: x.reason.trim(),
      quantity: 1,
      unitPrice: finite(x.amount, "phụ phí", { min: 1, integer: true }),
      amount: Number(x.amount),
      type: "extra",
    });
  }
  const total = lines.reduce((sum, l) => sum + l.amount, 0);
  if (!Number.isSafeInteger(total) || total <= 0)
    fail("Tổng tiền không hợp lệ");
  const term = finite(room.paymentTermDays ?? 5, "hạn thanh toán", {
    integer: true,
  });
  if (term > 60) fail("Hạn thanh toán tối đa 60 ngày");
  return {
    period: p,
    meterPeriod,
    roomId: contract.roomId,
    roomName: room.name,
    contractId: contract._id,
    contractNumber: contract.number,
    tenantId: contract.tenantId,
    tenantName: contract.tenantName,
    recipientUid: contract.recipientUid || "",
    issueDate: day,
    dueDate: addDays(day, term),
    lines,
    total,
    status: "unpaid",
    bank: contract.bank || {},
    delivered: !!contract.recipientUid,
  };
}
module.exports = {
  finite,
  date,
  today,
  period,
  previousPeriod,
  nextPeriod,
  billingDate,
  addDays,
  overdueDays,
  lateAlert,
  invoiceId,
  buildInvoice,
};
