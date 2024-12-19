<script lang="ts">
    import Plot from "svelte-plotly.js";

    let {
        plotdata,
        measdata,
        title,
        title_x,
        title_y,
        xaxis_is_log,
        yaxis_is_log
    } = $props();
</script>

<Plot
data={plotdata.concat((measdata == undefined)? [] : measdata.filter((trace) => trace.checked))}
layout={{
    title: title,
    xaxis: {
        type: xaxis_is_log ? "log" : "",
        autorange: "true",
        title: title_x,
    },
    yaxis: {
        type: yaxis_is_log ? "log" : "",
        autorange: "true",
        title: title_y,
    },
    margin: { t: 30 },
}}
fillParent="width"
debounce={250}
/>