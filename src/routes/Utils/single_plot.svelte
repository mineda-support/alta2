<script>
    import Plot from "svelte-plotly.js";

    export let plotdata;
    export let measdata;
    export let title;
    export let title_x;
    export let title_y;
    export let xaxis_is_log;
    export let yaxis_is_log;    
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