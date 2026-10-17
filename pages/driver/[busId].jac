"""/driver/:busId - driver view (no login in the demo). Route shell owned by Dev C (screens live in driver/)."""

import from "@jac/runtime" { useParams }
import from ...driver.DriverApp { DriverApp }

def:pub DriverPage -> JsxPage {
    params: any = useParams();
    p_dict: dict[str, any] = dict(params) if params else {};
    bus_id = str(p_dict.get("busId", "MB-101"));
    return <DriverApp busId={bus_id} />;
}
