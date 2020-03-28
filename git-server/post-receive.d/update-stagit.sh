#!/bin/sh

# NOTE: needs to be set for correct locale (expects UTF-8) otherwise the
#       default is LC_CTYPE="POSIX".
export LC_CTYPE="en_US.UTF-8"

# This is the directory of the repo when called from the post-receive script.
name=$(basename "$(pwd)")

# config
# paths must be absolute.
reposdir="/home/git"
dir="${reposdir}/${name}"
htmldir="/var/www/git.crocker.im/html"
stagitdir="/"
destdir="${htmldir}${stagitdir}"
cachefile=".htmlcache"
# /config

if ! test -d "${dir}"; then
	echo "${dir} does not exist" >&2
	exit 1
fi
cd "${dir}" || exit 1

# Only build pages for published repos
if ! test -f "git-daemon-export-ok"; then
	exit 0
fi

# Set a URL if none exists
if ! test -f "url"; then
	echo "git://git.crocker.im/${name}" > url
fi

# Set an owner if none exists
if ! test -f "owner"; then
	echo "David Crocker <david@crocker.im>" > owner
fi

# detect git push -f
force=0
while read -r old new ref; do
	test "${old}" = "0000000000000000000000000000000000000000" && continue
	test "${new}" = "0000000000000000000000000000000000000000" && continue

	hasrevs=$(git rev-list "${old}" "^${new}" | sed 1q)
	if test -n "${hasrevs}"; then
		force=1
		break
	fi
done

# strip .git suffix.
r=$(basename "${name}")
d=$(basename "${name}" ".git")
printf "[%s] stagit HTML pages... " "${d}"

mkdir -p "${destdir}/${d}"
cd "${destdir}/${d}" || exit 1

# remove commits and ${cachefile} on git push -f, this recreated later on.
if test "${force}" = "1"; then
	rm -f "${cachefile}"
	rm -rf "commit"
fi

# make index.
#stagit-index "${reposdir}/"*/ > "${destdir}/index.html"

# make pages.
stagit -c "${cachefile}" "${reposdir}/${r}"

ln -sf log.html index.html
ln -sf ../style.css style.css
ln -sf ../logo.png logo.png

echo "done"
