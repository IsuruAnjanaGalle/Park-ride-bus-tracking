"""Admin panel root. Placeholder from milestone 0; Dev C owns admin/ and replaces this."""

import from ..components.shared.api { admin_bus_list }

def:pub AdminApp -> JsxElement {
    has count: int = 0,
        status: str = "loading";

    async can with entry {
        env: dict[str, any] = {};
        env = await admin_bus_list();
        if env["ok"] {
            count = len(env["data"]["buses"]);
            status = "ready";
        } else {
            status = env["error"]["message"];
        }
    }

    return <main data-theme="night" className="min-h-dvh p-6 flex flex-col gap-3" style={{"background": "var(--bg)", "color": "var(--text)"}}>
        <h1 className="text-3xl font-bold">Admin panel</h1>
        <p>Placeholder. Dev C builds Home, Bus account and Demo console here.</p>
        <p role="status">{"Buses from admin_bus_list: " + str(count) if status == "ready" else status}</p>
    </main>;
}
