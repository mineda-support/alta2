<script lang="ts">
    let { lab, val = $bindable() } = $props();
</script>

<label>{lab}
<input
    bind:value={val}
    style="border:darkgray solid 1px; width: 10%;"
/></label>