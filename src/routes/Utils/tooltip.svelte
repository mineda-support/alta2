<script module>
    export function tooltip(node, fn) {
        $effect(() => {
            const tooltip = tippy(node, fn());

            return tooltip.destroy;
        });
    }
</script>

<script lang="ts">
    import tippy from "tippy.js";
</script>
