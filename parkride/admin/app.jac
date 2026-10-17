"""Admin and Driver Web Application Entry Point.

Serves the Admin Panel (/admin) and Driver Console (/driver/:busId)
with interactive route switching and mock support.
"""

cl import from admin.admin { AdminView }
cl import from driver.driver { DriverView }

cl def:pub app -> JsxElement {
    has currentPath: str = "admin";

    def show_admin { currentPath = "admin"; }
    def show_driver { currentPath = "driver"; }

    return
        <div>
            <div
                style={{"position": "fixed", "top": "12px", "right": "24px", "zIndex": 1000, "display": "flex", "alignItems": "center", "gap": "8px", "backgroundColor": "rgba(15, 23, 42, 0.95)", "padding": "6px 12px", "borderRadius": "30px", "border": "1px solid rgba(56, 189, 248, 0.5)", "boxShadow": "0 4px 20px rgba(0,0,0,0.6)"}}
            >
                <span style={{"fontSize": "12px", "color": "#94a3b8", "fontWeight": "700", "textTransform": "uppercase"}}>
                    {"VIEW:"}
                </span>
                <button
                    className={"nav-tab-btn " + ("nav-tab-active" if currentPath == "admin" else "")}
                    style={{"padding": "4px 12px", "fontSize": "13px"}}
                    onClick={show_admin}
                    id="switch-admin-view"
                >
                    {"/admin"}
                </button>
                <button
                    className={"nav-tab-btn " + ("nav-tab-active" if currentPath == "driver" else "")}
                    style={{"padding": "4px 12px", "fontSize": "13px"}}
                    onClick={show_driver}
                    id="switch-driver-view"
                >
                    {"/driver/MB-101"}
                </button>
            </div>

            {<AdminView/> if currentPath == "admin" else <DriverView busId="MB-101"/>}
        </div>;
}
