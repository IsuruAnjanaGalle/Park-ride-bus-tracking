"""Root layout: wraps every route. Owner: Dev A (shared - changes need two reviews)."""

import from "@jac/runtime" { Outlet }

def:pub RootLayout -> JsxLayout {
    <div className="min-h-dvh">
        <Outlet />
    </div>
}
