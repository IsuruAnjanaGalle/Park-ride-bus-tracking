"""/driver/:busId - driver view (no login in the demo). Route shell owned by Dev C (screens live in driver/)."""

import from "@jac/runtime" { useParams }
import from ...driver.DriverApp { DriverApp }

def:pub DriverPage -> JsxPage {
    params = useParams();
    bus_id = params["busId"];
    if not bus_id {
        return <p>No bus id.</p>;
    }
    <DriverApp busId={bus_id} />
}
