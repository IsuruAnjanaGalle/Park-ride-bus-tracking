"""Shows its children only to a logged-in user with `role`; otherwise a link to log in.

Usage: <RoleGuard role="admin" next="/admin"><AdminApp /></RoleGuard>. Owner: Dev A.
"""

import from "@jac/runtime" { Link }
import from .api { current_user }

def:pub RoleGuard(role: str, next: str = "/", children: any = None) -> JsxElement {
    user = current_user();
    if user is None {
        return <main className="mx-auto max-w-md p-4 flex flex-col gap-3">
            <h1 className="text-2xl font-bold">Login required</h1>
            <Link to={"/login?next=" + next}>Log in to continue</Link>
        </main>;
    }
    if user["role"] != role {
        return <main className="mx-auto max-w-md p-4 flex flex-col gap-3">
            <h1 className="text-2xl font-bold">Not allowed</h1>
            <p>{"This page needs the " + role + " role. You are logged in as " + user["username"] + "."}</p>
            <Link to={"/login?next=" + next}>Log in as another user</Link>
        </main>;
    }
    <>{children}</>
}
