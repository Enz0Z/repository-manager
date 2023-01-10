const https = require('https');
const fs = require('fs');
const JSZip = require('./server/jszip.min.js');

exports('GenerateBin', async (path, url, self) => {
	return new Promise((resolve, error) => {
		if (fs.existsSync(path)) {
			resolve();
			return;
		}
		const options = {
			'method': 'GET'
		}

		if (self.repository.token !== undefined) options.headers = { 'Authorization': self.repository.token }
		https.request(url, options, function (res) {
			res.on('data', function (chunk) {
				fs.appendFileSync(path, chunk);
			});

			res.on('end', function (chunk) {
				resolve()
			});

			res.on('error', function (e) {
				error(e);
			});
		}).end();
	}).then(function() {
		return new Promise((resolve, error) => {
			if (fs.existsSync(path + '.bin')) {
				resolve();
				return;
			}
			new JSZip().loadAsync(fs.readFileSync(path)).then(async function (zip) {
				if (fs.existsSync(path + '.bin')) fs.unlinkSync(path + '.bin');

				for (const filename in zip.files) {
					if (zip.files[filename].dir) continue;
					var file_path = filename.substring(filename.indexOf('/') + 1, filename.length);
					var ignore = self.repository.ignore;
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
							fs.appendFileSync(path + '.bin', JSON.stringify([ file_path, raw ]) + '\n');
							return file_path;
						});
					}
				}
				resolve();
			})
		})
	})
})

exports('CreatePath', async (path) => {
	fs.mkdirSync(path.substring(0, path.lastIndexOf('/') + 1), { recursive: true });
})

exports('GetBuild', async () => {
	try {
		const regex = /v1\.0\.0\.(\d{4,5})\s*/;
		const res = regex.exec(GetConvar('version'));

		return parseInt(res[1]);
	} catch (error) {
		return 0;
	}
})