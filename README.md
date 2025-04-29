# Digital Masterpiece Registry

The **Digital Masterpiece Registry** is a Clarity smart contract that enables artists and creators to register their digital works immutably on the Stacks blockchain. It provides a secure and permissioned framework for managing artwork metadata, controlling access, and transferring ownership.

## 🚀 Features

- ✅ Immutable registration of digital artworks with enforced metadata rules
- ✅ Ownership rights with transferable artist authority
- ✅ Role-based access for permissioned viewing
- ✅ Validation for name, dimensions, and category tagging
- ✅ Ability to update or remove registered works (artist-only)
- ✅ Category tagging for classification and searchability

## 🔐 Permission System

- Only the original artist (uploader) can modify or transfer ownership.
- Viewing permissions are granted to artists by default and can be extended to others.
- Admin-only actions (if any) are enforced via `REGISTRY-ADMINISTRATOR`.

## 🛠 Contract Structure

- `masterpiece-registry` (map): Stores metadata about each registered piece.
- `viewing-permissions` (map): Tracks view access rights on a per-artwork, per-user basis.
- `masterpiece-count` (var): Tracks total registered artworks.

### Key Public Functions

| Function | Description |
|---------|-------------|
| `register-masterpiece` | Register a new digital artwork |
| `retrieve-masterpiece-notes` | Fetch artist notes from a registered piece |
| `verify-viewing-access` | Check if a user has viewing rights |
| `count-masterpiece-categories` | Get the number of categories attached to a piece |
| `validate-masterpiece-name` | Validate the name format |
| `transfer-masterpiece-rights` | Transfer ownership to a new artist |
| `update-masterpiece-details` | Modify artwork metadata (only by current owner) |
| `remove-masterpiece` | Permanently remove a piece (owner only) |

## ⛓ Blockchain Platform

- **Stacks Blockchain**
- **Language:** Clarity

## 📦 Deployment

```lisp
;; Use the Clarity CLI or Hiro tools
clarity-cli check digital-masterpiece-registry.clar
clarity-cli launch digital-masterpiece-registry.clar
