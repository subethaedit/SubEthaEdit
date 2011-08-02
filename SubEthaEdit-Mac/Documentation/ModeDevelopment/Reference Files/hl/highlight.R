all.equal <- function(target, current, ...) UseMethod("all.equal")

all.equal.default <-
    function(target, current, check.attributes = TRUE, ...)
{
    ## Really a dispatcher given mode() of args :
    ## use data.class as unlike class it does not give "Integer"
    if(is.language(target) || is.function(target) || is.environment(target))
	return(all.equal.language(target, current, ...))
    if(is.recursive(target))
	return(all.equal.list(target, current, ...))
    msg <- c(if(check.attributes) attr.all.equal(target, current, ...),
	     if(is.numeric(target)) {
		 all.equal.numeric(target, current, check.attributes = check.attributes, ...)
	     } else
	     switch (mode(target),
		     logical = ,
		     complex = ,
		     numeric = all.equal.numeric(target, current, check.attributes = check.attributes, ...),
		     character = all.equal.character(target, current, check.attributes = check.attributes, ...),
		      if(data.class(target) != data.class(current)) {
		 paste("target is ", data.class(target), ", current is ",
		       data.class(current), sep = "")
	     } else NULL))
    if(is.null(msg)) TRUE else msg
}

all.equal.numeric <-
    function(target, current, tolerance = .Machine$double.eps ^ .5,
             scale = NULL, check.attributes = TRUE, ...)
{
    msg <- if(check.attributes) attr.all.equal(target, current, ...)
    if(data.class(target) != data.class(current)) {
	msg <- c(msg, paste("target is ", data.class(target), ", current is ",
			    data.class(current), sep = ""))
	return(msg)
    }

    lt <- length(target)
    lc <- length(current)
    cplx <- is.complex(target)
    if(lt != lc) {
	## *replace* the 'Lengths' msg[] from attr.all.equal():
	if(!is.null(msg)) msg <- msg[- grep("\\bLengths\\b", msg)]
	msg <- c(msg, paste(if(cplx)"Complex" else "Numeric",
			    ": lengths (", lt, ", ", lc, ") differ", sep = ""))
	return(msg)
    }
    target <- as.vector(target)
    current <- as.vector(current)
    out <- is.na(target)
    if(any(out != is.na(current))) {
	msg <- c(msg, paste("'is.NA' value mismatches:", sum(is.na(current)),
			    "in current,", sum(out), " in target"))
	return(msg)
    }
    out <- out | target == current
    if(all(out)) { if (is.null(msg)) return(TRUE) else return(msg) }

    target <- target[!out]
    current <- current[!out]
    if(is.integer(target) && is.integer(current)) target <- as.double(target)
    xy <- mean((if(cplx)Mod else abs)(target - current))
    what <-
	if(is.null(scale)) {
	    xn <- mean(abs(target))
	    if(is.finite(xn) && xn > tolerance) {
		xy <- xy/xn
		"relative"
	    } else "absolute"
	} else {
	    xy <- xy/scale
	    "scaled"
	}

    if(is.na(xy) || xy > tolerance)
       msg <- c(msg, paste("Mean", what, if(cplx)"Mod", "difference:", format(xy)))

    if(is.null(msg)) TRUE else msg
}

all.equal.character <-
    function(target, current, check.attributes = TRUE, ...)
{
    msg <-  if(check.attributes) attr.all.equal(target, current, ...)
    if(data.class(target) != data.class(current)) {
	msg <- c(msg, paste("target is ", data.class(target), ", current is ",
			    data.class(current), sep = ""))
	return(msg)
    }
    lt <- length(target)
    lc <- length(current)
    if(lt != lc) {
	if(!is.null(msg)) msg <- msg[- grep("\\bLengths\\b", msg)]
	msg <- c(msg, paste("Lengths (", lt, ", ", lc,
		     ") differ (string compare on first ", ll <- min(lt, lc),
		     ")", sep = ""))
	ll <- seq(length = ll)
	target <- target[ll]
	current <- current[ll]
    }
    nas <- is.na(target)
    if (any(nas != is.na(current))) {
	msg <- c(msg, paste("'is.NA' value mismatches:", sum(is.na(current)),
		     "in current,", sum(nas), " in target"))
	return(msg)
    }
    ne <- !nas & (target != current)
    if(!any(ne) && is.null(msg)) TRUE
    else if(any(ne)) c(msg, paste(sum(ne), "string mismatches"))
    else msg
}

all.equal.factor <- function(target, current, check.attributes = TRUE, ...)
{
    if(!inherits(current, "factor"))
	return("'current' is not a factor")
    msg <-  if(check.attributes) attr.all.equal(target, current)
    class(target) <- class(current) <- NULL
    nax <- is.na(target)
    nay <- is.na(current)
    if(n <- sum(nax != nay))
	msg <- c(msg, paste("NA mismatches:", n))
    else {
	target <- levels(target)[target[!nax]]
	current <- levels(current)[current[!nay]]
	if(is.character(n <- all.equal(target, current, check.attributes = check.attributes)))
	    msg <- c(msg, n)
    }
    if(is.null(msg)) TRUE else msg
}

all.equal.formula <- function(target, current, ...)
{
    if(length(target) != length(current))
	return(paste("target, current differ in having response: ",
		     length(target) == 3, ", ", length(current) == 3))
    if(all(deparse(target) != deparse(current)))
	"formulas differ in contents"
    else TRUE
}

all.equal.language <- function(target, current, check.attributes = TRUE, ...)
{
    mt <- mode(target)
    mc <- mode(current)
    if(mt == "expression" && mc == "expression")
	return(all.equal.list(target, current, check.attributes = check.attributes, ...))
    ttxt <- paste(deparse(target), collapse = "\n")
    ctxt <- paste(deparse(current), collapse = "\n")
    msg <- c(if(mt != mc)
	     paste("Modes of target, current: ", mt, ", ", mc, sep = ""),
	     if(ttxt != ctxt) {
		 if(pmatch(ttxt, ctxt, FALSE))
		     "target a subset of current"
		 else if(pmatch(ctxt, ttxt, FALSE))
		     "current a subset of target"
		 else	"target, current don't match when deparsed"
	     })
    if(is.null(msg)) TRUE else msg
}

all.equal.list <- function(target, current, check.attributes = TRUE, ...)
{
    msg <- if(check.attributes) attr.all.equal(target, current, ...)
##    nt <- names(target)
##    nc <- names(current)
    iseq <-
	## <FIXME>
	## Commenting this eliminates PR#674, and assumes that lists are
	## regarded as generic vectors, so that they are equal iff they
	## have identical names attributes and all components are equal.
	## if(length(nt) && length(nc)) {
	##     if(any(not.in <- (c.in.t <- match(nc, nt, 0)) == 0))
	##	msg <- c(msg, paste("Components not in target:",
	##			    paste(nc[not.in], collapse = ", ")))
	##     if(any(not.in <- match(nt, nc, 0) == 0))
	##	msg <- c(msg, paste("Components not in current:",
	##			    paste(nt[not.in], collapse = ", ")))
	##     nt[c.in.t]
	## } else
	## </FIXME>
	if(length(target) == length(current)) {
	    seq(along = target)
	} else {
            if(!is.null(msg)) msg <- msg[- grep("\\bLengths\\b", msg)]
	    nc <- min(length(target), length(current))
	    msg <- c(msg, paste("Length mismatch: comparison on first",
				nc, "components"))
	    seq(length = nc)
	}
    for(i in iseq) {
	mi <- all.equal(target[[i]], current[[i]], check.attributes = check.attributes, ...)
	if(is.character(mi))
	    msg <- c(msg, paste("Component ", i, ": ", mi, sep=""))
    }
    if(is.null(msg)) TRUE else msg
}


attr.all.equal <- function(target, current,
                           check.attributes = TRUE, check.names = TRUE, ...)
{
    ##--- "all.equal(.)" for attributes ---
    ##---  Auxiliary in all.equal(.) methods --- return NULL or character()
    msg <- NULL
    if(mode(target) != mode(current))
	msg <- paste("Modes: ", mode(target), ", ", mode(current), sep = "")
    if(length(target) != length(current))
	msg <- c(msg, paste("Lengths: ", length(target), ", ",
			    length(current), sep = ""))
    ax <- attributes(target)
    ay <- attributes(current)
    if(check.names) {
        nx <- names(target)
        ny <- names(current)
        if((lx <- length(nx)) | (ly <- length(ny))) {
            ## names() treated now; hence NOT with attributes()
            ax$names <- ay$names <- NULL
            if(lx && ly) {
                if(is.character(m <- all.equal.character(nx, ny, check.attributes = check.attributes)))
                    msg <- c(msg, paste("Names:", m))
            } else if(lx)
                msg <- c(msg, "names for target but not for current")
            else msg <- c(msg, "names for current but not for target")
        }
    }
    if(check.attributes && (length(ax) || length(ay))) {# some (more) attributes
	## order by names before comparison:
	nx <- names(ax)
	ny <- names(ay)
	if(length(nx)) ax <- ax[order(nx)]
	if(length(ny)) ay <- ay[order(ny)]
	tt <- all.equal(ax, ay, check.attributes = check.attributes, ...)
	if(is.character(tt)) msg <- c(msg, paste("Attributes: <", tt, ">"))
    }
    msg # NULL or character
}

