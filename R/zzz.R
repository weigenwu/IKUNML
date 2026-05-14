.onAttach <- function(libname, pkgname) {
  messages <- c(
    "\u522b\u611f\u5192",
    "\u505a\u4e00\u4e2a\u771f\u6b63\u7684man",
    "\u54ce\u5466\u4f60\u5e72\u561b",
    "\u7231\u4f60\u4e00\u5764\u5e74",
    "\u5764\u4f60\u592a\u7f8e",
    "\u5764\u54e5\u9a7e\u5230"
  )
  packageStartupMessage(sample(messages, 1L))
}
