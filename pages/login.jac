"""/login - minimal working login for the seeded demo users. Dev B may restyle it.

?next=/admin returns there after logging in.
"""

import from "@jac/runtime" { useNavigate, useLocation }
import from ..components.shared.api { login }

def:pub LoginPage -> JsxPage {
    has username: str = "",
        password: str = "",
        message: str = "",
        busy: bool = False;
    nav = useNavigate();
    location = useLocation();

    async def do_login(e: FormEvent) {
        e.preventDefault();
        env: dict[str, any] = {};
        busy = True;
        env = await login(username, password);
        busy = False;
        if not env["ok"] {
            message = env["error"]["message"];
            return;
        }
        search: str = location.search or "";
        nxt = search.split("next=")[1] if "next=" in search else "";
        target = nxt or ("/admin" if env["data"]["role"] == "admin" else "/");
        nav(target);
    }

    return <main className="mx-auto max-w-sm p-4 flex flex-col gap-4">
        <h1 className="text-2xl font-bold">Log in</h1>
        <form onSubmit={do_login} className="flex flex-col gap-3">
            <label className="flex flex-col gap-1">
                <span>Username</span>
                <input
                    className="min-h-11 rounded-lg border px-3 text-base text-black"
                    value={username}
                    autoComplete="username"
                    onChange={lambda (e: ChangeEvent) { username = e.target.value; }}
                />
            </label>
            <label className="flex flex-col gap-1">
                <span>Password</span>
                <input
                    className="min-h-11 rounded-lg border px-3 text-base text-black"
                    type="password"
                    value={password}
                    autoComplete="current-password"
                    onChange={lambda (e: ChangeEvent) { password = e.target.value; }}
                />
            </label>
            <button type="submit" disabled={busy} className="min-h-11 rounded-lg font-semibold" style={{"background": "var(--accent)", "color": "var(--accent-ink)"}}>
                {"Logging in..." if busy else "Log in"}
            </button>
            <p role="status" aria-live="polite">{message}</p>
        </form>
        <p className="text-sm opacity-80">Demo logins: passenger / demo-passenger, admin / demo-admin.</p>
    </main>;
}
