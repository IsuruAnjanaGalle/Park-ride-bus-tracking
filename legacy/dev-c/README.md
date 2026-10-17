# legacy/dev-c — Dev C's admin and driver screens from PR #2 (pre-0.37 layout)

Not compiled or bundled (`jac.toml [check] exclude`, `.jacignore`). Port each file into the 0.37 layout:
- `admin/admin.cl.jac` → `admin/AdminApp.jac` (mounted at `/admin` by `pages/admin/index.jac`)
- `driver/driver.cl.jac` → `driver/DriverApp.jac` (mounted at `/driver/:busId`)
- `components/admin/*.cl.jac` → `components/admin/*.jac`
Rename `.cl.jac` → `.jac`, drop `cl { }` wrappers, call data through `components/shared/api.jac` (not SampleData), and use `styles/tokens.css` variables. Then delete this folder.
