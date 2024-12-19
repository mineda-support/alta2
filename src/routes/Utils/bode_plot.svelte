<script lang="ts">
    import Plot from "svelte-plotly.js";

    let {
        db_data,
        ph_data,
        title,
        title_x,
        title_y1,
        title_y2
    } = $props();
</script>

<Plot
    data={db_data}
    layout={{
        title: title,
        xaxis: {
            type: "log",
            autorange: "true",
            linewidth: 1,
            mirror: true,
        },
        yaxis: {
            autorange: "true",
            linewidth: 1,
            mirror: true,
            title: title_y1,
        },
        margin: { t: 30 },
    }}
    fillParent="width"
    debounce={250}
/>
<Plot
    data={ph_data}
    layout={{
        xaxis: {
            type: "log",
            autorange: "true",
            linewidth: 1,
            mirror: true,
            title: title_x,
        },
        yaxis: {
            autorange: "true",
            linewidth: 1,
            mirror: true,
            title: title_y2,
        },
        margin: { t: 30 },
    }}
    fillParent="width"
    debounce={250}
/>
