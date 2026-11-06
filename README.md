# room-rental-management-system
Room Rental Management System - Capstone Project

## Firestore ownership

Business documents in `rooms`, `tenants`, `services`, `meters`, `contracts`,
`extras`, `maintenance`, `invoices`, and `notifications` include `ownerId`,
which is the Firebase Auth UID of the landlord. Existing relationship fields
such as `roomId`, `tenantId`, `contractId`, and `serviceId` continue to store
the corresponding Firestore document IDs. Landlord settings are stored at
`settings/{ownerId}`.

For a database created before this schema, sign in as the landlord who owns
that data and use **Gán dữ liệu cũ cho tài khoản này** once. This assigns
`ownerId` to legacy documents that do not yet have one; it does not overwrite
documents already assigned to another owner. Deploy the updated Firestore
rules, indexes, and Cloud Functions before using the migration or creating
owner-scoped records:

```sh
firebase deploy --project quan-li-phong --only firestore:rules,firestore:indexes,functions
```

Automatic invoice creation requires the `billingHourly` scheduled Cloud
Function to be deployed and `settings/{ownerId}.autoBilling` to be enabled.
The function checks each active rental contract hourly and creates the current
period's invoice on or after that room's billing day. Tenants receive an in-app
invoice notification only when their account is linked to the tenant record.
Deploying Cloud Functions requires the Firebase project to use the Blaze
(pay-as-you-go) plan.
