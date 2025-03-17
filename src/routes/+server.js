import fs from 'fs';
import { globSync } from 'node:fs'
import { json } from '@sveltejs/kit';

export async function POST({ request, cookies }) {
    // console.log(request);
	const props = await request.json();
    const wdir = props.wdir;
    const file_name = props.file_name;
    const edifdata = props.edifdata;
    console.log(wdir);
    fs.writeFileSync(wdir+file_name, edifdata);
    const edif_files = globSync(wdir + '*.txt');
	return json(edif_files, { status: 201 });
}
