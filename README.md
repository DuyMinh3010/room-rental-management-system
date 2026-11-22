# room-rental-management-system
Room Rental Management System - Capstone Project

## Firestore ownership

Business documents in `rooms`, `tenants`, `services`, `meters`, `contracts`,
`extras`, `maintenance`, `invoices`, and `notifications` include `ownerId`,
which is the Firebase Auth UID of the landlord. Existing relationship fields
such as `roomId`, `tenantId`, `contractId`, and `serviceId` continue to store
the corresponding Firestore document IDs. Landlord settings are stored at
`settings/{ownerId}`.

Service documents in `services/{id}` also store `id` equal to their Firestore
document ID. Rooms and contracts reference services by ID, and invoice lines
retain the same `serviceId`, so service records are not duplicated in those
documents.

For a database created before this schema, sign in as the landlord who owns
that data and use **Gán dữ liệu cũ cho tài khoản này** once. This assigns
`ownerId` to legacy documents that do not yet have one and fills missing or
incorrect service `id` fields; it does not overwrite documents already assigned
to another owner. Use **Cập nhật ID dịch vụ cũ** to backfill service IDs for this
owner without changing ownership. Deploy the Firestore rules and indexes before using the tenant portal on the
Spark plan:

```sh
firebase deploy --project quan-li-phong --only firestore:rules,firestore:indexes
```

Automatic invoice creation requires the `billingHourly` scheduled Cloud
Function to be deployed and `settings/{ownerId}.autoBilling` to be enabled.
The function checks each active rental contract hourly and creates the current
period's invoice on or after that room's billing day. Tenants receive an in-app
invoice notification only when their account is linked to the tenant record.
Cloud Functions (including automatic invoice creation and legacy data
migration) require the Firebase project to use the Blaze (pay-as-you-go) plan;
they are not required for tenant portal access on Spark.

## Tenant account linking

The landlord enters the tenant's sign-in email in the tenant profile. Tenant
accounts must verify that email, sign in, and confirm the matching profile in
the tenant screen. The app links the verified Firebase Auth UID to that tenant
record. Linking writes the tenant UID and a minimal tenant-to-room mapping in
one Firestore transaction. Firestore rules require both writes to match the
verified account email. Invoices created before linking must be resent by the
landlord; new invoices are addressed to the linked account automatically.

After linking, the tenant portal provides an overview, invoice and payment
tracking, assigned services and meter readings, read-only contract details,
maintenance request submission and progress, and account settings. The portal
reads and writes Firestore directly under tenant-scoped security rules; tenants
can access only their linked room and records. Maintenance requests contain a
description and do not require Firebase Storage or Cloud Functions.
