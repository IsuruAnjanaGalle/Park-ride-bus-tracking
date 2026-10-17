"""Root layout: wraps every route. Owner: Dev A (shared - changes need two reviews)."""

cl import from "@jac/runtime" { Outlet }

def:pub RootLayout -> JsxLayout {
    return <div className="min-h-dvh">
        <Outlet />
    </div>;
}
