"""Who is signed in, with Switch user and Log out (docs/decisions.md D-30). Owner: Dev A."""

import from "@jac/runtime" { useNavigate }
import from .api { current_user, logout }

def:pub AccountBar -> JsxElement {
    nav = useNavigate();
    user = current_user();

    def do_logout(_e: MouseEvent) {
        logout();
        nav("/login");
    }

    if user is None {
        return <></>;
    }
    <div
        role="region"
        aria-label="Account"
        data-theme="night"
        className="flex flex-wrap items-center justify-end gap-2 px-4 py-2 text-sm"
        style={{"background": "var(--surface)", "borderBottom": "1px solid var(--border)", "color": "var(--text)"}}
    >
        <span>{"Signed in as " + user["username"] + " (" + user["role"] + ")"}</span>
        <button
            type="button"
            className="min-h-11 px-4 rounded-xl"
            style={{"border": "1px solid var(--border)", "color": "var(--text)"}}
            onClick={lambda (_e: MouseEvent) { nav("/login"); }}
        >
            Switch user
        </button>
        <button
            type="button"
            className="min-h-11 px-4 rounded-xl font-semibold"
            style={{"background": "var(--accent)", "color": "var(--accent-ink)"}}
            onClick={do_logout}
        >
            Log out
        </button>
    </div>
}
