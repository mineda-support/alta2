<script lang="ts">
    import { tooltip, msg } from "./tooltip.svelte";
    let { tooltip_msg, lab, val = $bindable() } = $props();
</script>

<label use:tooltip={() => msg(tooltip_msg)}
    >{lab}
    <input
        bind:value={val}
        style="border:darkgray solid 1px; width: 10%;"
    /></label
>
