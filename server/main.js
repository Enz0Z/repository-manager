const fs = require('fs');
const JSZip = require('./server/jszip.min.js');

exports('getFilesInZip', async (dump, ignore) => {
	return new Promise((resolve) => {
		JSZip.loadAsync(dump, { base64: true }).then(async function (zip) {
			var files = [];

			for (const filename in zip.files) {
				if (zip.files[filename].dir) continue;
				var file_path = filename.substring(filename.indexOf('/') + 1, filename.length);
				var write = true;

				for (let i = 0; i < ignore.length; i++) {
					const name = ignore[i];

					if (name.endsWith('/') && file_path.startsWith(name)) {
						write = false;
						break;
					}
					if (file_path == name) {
						write = false;
						break;
					}
				}
				if (write) {
					await zip.files[filename].async('base64').then(function (raw) {
						files.push({
							path: file_path,
							raw: raw
						})
					})
				}
			}
			resolve(files);
		})
	})
})

exports('createPath', async (path) => {
	fs.mkdirSync(path.substring(0, path.lastIndexOf('/') + 1), { recursive: true });
})

exports('getBuild', async () => {
	try {
		const regex = /v1\.0\.0\.(\d{4,5})\s*/;
		const res = regex.exec(GetConvar('version'));

		return parseInt(res[1]);
	} catch (error) {
		return 0;
	}
})