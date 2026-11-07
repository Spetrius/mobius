# Appended to the AUR PKGBUILD by build-repo.sh. Bambu's AppImage stores its folders as 0700,
# and the PKGBUILD copies them as they are, so /opt/bambustudio-bin/bin was readable by root only
# and the app failed with "Permission denied". Run the upstream package(), then open the folders up.
eval "_upstream_$(declare -f package)"
package() {
  _upstream_package
  find "$pkgdir" -type d -exec chmod 755 {} +
}
