"""Driver view root. Placeholder from milestone 0; Dev C owns driver/ and replaces this."""

import from ..components.shared.api { get_driver_view }

def:pub DriverApp(busId: str) -> JsxElement {
    has text: str = "loading";

    async can with entry {
        env: dict[str, any] = {};
        env = await get_driver_view(busId);
        text = env["data"]["instruction"]["text"] if env["ok"] else env["error"]["message"];
    }

    <main data-theme="night" className="min-h-dvh p-6 flex flex-col gap-3" style={{"background": "var(--bg)", "color": "var(--text)"}}>
        <h1 className="text-3xl font-bold">{"Driver view - " + busId}</h1>
        <p>Placeholder. Dev C builds the turn instruction bar and Report incident here.</p>
        <p role="status">{text}</p>
    </main>
}
