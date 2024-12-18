<script>
    export let lab;
    export let val;
</script>

<label>{lab}
<input
    bind:value={val}
    style="border:darkgray solid 1px; width: 10%;"
/></label>