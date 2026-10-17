"""/ - passenger app. Placeholder from milestone 0; Dev B owns this page."""

import from "@jac/runtime" { Link }

def:pub PassengerHome -> JsxPage {
    <main className="mx-auto max-w-md p-4 flex flex-col gap-4">
        <h1 className="text-3xl font-bold">Park &amp; Ride Sri Lanka</h1>
        <p>Passenger app placeholder. Dev B builds the landing pop-up here.</p>
        <nav className="flex flex-wrap gap-3">
            <Link to="/login">Log in</Link>
            <Link to="/admin">Admin</Link>
            <Link to="/driver/MB-101">Driver MB-101</Link>
            <Link to="/dev/core">Core console</Link>
        </nav>
    </main>
}
