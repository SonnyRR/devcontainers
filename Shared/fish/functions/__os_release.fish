# Reads a field (e.g. NAME, PRETTY_NAME) from /etc/os-release, so the shared fish
# functions work unchanged across every image flavor & derived images.
function __os_release --argument-names field
    string replace -rf "^$field=\"?([^\"]*)\"?\$" '$1' </etc/os-release 2>/dev/null
end
