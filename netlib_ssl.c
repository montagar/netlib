/*
**++
**  FACILITY:	NETLIB
**
**  ABSTRACT:	Routines specific to OpenSSL.
**
**  MODULE DESCRIPTION:
**
**  	The problem 
**
**  AUTHOR: 	    Tim Sneddon
**
**  Copyright (c) 2013, Endless Software Solutions.
**
**  All rights reserved.
**
**  Redistribution and use in source and binary forms, with or without
**  modification, are permitted provided that the following conditions
**  are met:
**
**      * Redistributions of source code must retain the above
**        copyright notice, this list of conditions and the following
**        disclaimer.
**      * Redistributions in binary form must reproduce the above
**        copyright notice, this list of conditions and the following
**        disclaimer in the documentation and/or other materials provided
**        with the distribution.
**      * Neither the name of the copyright owner nor the names of any
**        other contributors may be used to endorse or promote products
**        derived from this software without specific prior written
**        permission.
**
**  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
**  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
**  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
**  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
**  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
**  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
**  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
**  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
**  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
**  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
**  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
**  CREATION DATE:  07-FEB-2013
**
**  MODIFICATION HISTORY:
**
**  	07-FEB-2013 V1.0    Sneddon 	Initial coding.
**--
*/
#ifdef __DECC
#pragma module NETLIB_SSL "V1.0"
#else
#module NETLIB_SSL "V1.0"
#endif
#include "netlib_ssl.h"
#include "netlib.h"

/*
**  Forward declarations
*/

    unsigned int netlib_ssl_socket(struct CTX **xctx, void **xsocket,
                                   void **xssl);
    unsigned int netlib_ssl_accept(struct CTX **xctx,
				   struct NETLIBIOSBDEF *iosb,
			           void (*astadr)(), void *astprm);
    unsigned int netlib_ssl_connect(struct CTX **xctx, TIME *timeout,
				   struct NETLIBIOSBDEF *iosb,
			           void (*astadr)(), void *astprm);
    unsigned int netlib_ssl_shutdown(struct CTX **xctx,
				     struct NETLIBIOSBDEF *iosb,
			             void (*astadr)(), void *astprm);
    static unsigned int io_perform(struct IOR *IOR);
    static unsigned int io_read(struct IOR *ior);
    static unsigned int io_write(struct IOR *ior);
    static long outbio_callback(BIO *b, int oper, const char *argp, int argi,
				long argl, long retvalue);
    int netlib___cvt_status(int err, ...);

    /*
    ** These functions are needed by the DNS module
    */
    int netlib___get_nameservers(QUEUE *nsq) { return 0; }
    int netlib___get_domain(char *buf, unsigned short bufsize,
			    unsigned short *relenp) { return 0; }


/*
**  OWN storage
*/

    volatile unsigned netlib_ssl_efn = 0xffffffff;


/*
**
**  SS$_INSFMEM - unable to allocate internal SSL structures
**  SS$_BADCHECKSUM - key and cert do not match
*/
unsigned int netlib_ssl_context (void **xssl, unsigned int *method,
				 struct dsc$descriptor *cert_d, int *cert_type,
				 struct dsc$descriptor *key_d, int *key_type,
				 unsigned int *verify) {

    SSL_CTX *ssl;
    int argc, ret, status = SS$_NORMAL;
    char *cert = 0, *key = 0, *ptr;
    unsigned short len;

    SETARGCOUNT(argc);
SSL_library_init();
SSL_load_error_strings();
    ssl = SSL_CTX_new((*method == NETLIB_K_METHOD_SSL2) ? SSLv2_method() :
		      (*method == NETLIB_K_METHOD_SSL3) ? SSLv3_method() :
		      (*method == NETLIB_K_METHOD_TLS1) ? TLSv1_method() :
		       SSLv23_method());
    if (ssl == 0) return SS$_INSFMEM;

    status = lib$analyze_sdesc(cert_d, &len, &ptr);
    if (OK(status)) {
	cert = malloc(len+1);
	if (cert == 0) {
	    status = SS$_INSFMEM;
	} else {
	    memcpy(cert, ptr, len);
	    cert[len] = '\0';

	    status = lib$analyze_sdesc(key_d, &len, &ptr);
	    if (OK(status)) {
		key = malloc(len+1);
		if (key == 0) {
		    status = SS$_INSFMEM;
		} else {
		    memcpy(key, ptr, len);
		    key[len] = '\0';
		}
	    }
	}
    }

    if (OK(status)) {
	ret = SSL_CTX_use_certificate_file(ssl, cert, *cert_type);
	if (ret <= 0) {
	    status = vaxc$errno;
printf("use_cer,ret=%d,errno=%d,vaxc$errno=%d,%s\n",ret,errno,vaxc$errno,
		strerror(errno,vaxc$errno));
ret = ERR_peek_error();
printf("SSL = %d\n", ret);
printf("LIB = %d, FUNC = %d, REASON = %d\n", ERR_GET_LIB(ret),
		ERR_GET_FUNC(ret), ERR_GET_REASON(ret));
	} else {
	    ret = SSL_CTX_use_PrivateKey_file(ssl, key, *key_type);
	    if (ret <= 0) {
		status = vaxc$errno;
printf("use_priv,ret=%d,errno=%d,vaxc$errno=%d,%s\n",ret,errno,vaxc$errno,
		strerror(errno,vaxc$errno));
ret = ERR_peek_error();
printf("SSL = %d\n", ret);
printf("LIB = %d, FUNC = %d, REASON = %d\n", ERR_GET_LIB(ret),
		ERR_GET_FUNC(ret), ERR_GET_REASON(ret));
printf("\n");
	    } else {
		ret = SSL_CTX_check_private_key(ssl);
		if (ret <= 0) {
		    printf("errno=%d,ret=%d,vaxc$errno=%d,%s\n",
				errno,ret,vaxc$errno,
				strerror(errno,vaxc$errno));
		    status = SS$_BADCHECKSUM;
		}
	    }
	}
    }

    // if status OK and verify location path was supplied
	// SSL_CTX_load_verify_locations
	// if works
	    // SSL_CTX_set_erify(ssl, SSL_VERIFY_PEER, 0);
	    // SSL_CT_set_verify_depth(ssl, 1);
	// else
	    // RMS$_DNF?

    if (cert != 0) free(cert);
    if (key != 0) free(key);

    if (!OK(status)) {
	SSL_CTX_free(ssl);
    } else {
	*xssl = ssl;
    }
    return status;
} /* netlib_ssl_context */

/*
**++
**  ROUTINE:	netlib_ssl_socket
**
**  FUNCTIONAL DESCRIPTION:
**
**  	Create an SSL "socket".
**
**  RETURNS:	cond_value, longword (unsigned), write only, by value
**
**  PROTOTYPE:
**
**  	tbs
**
**  IMPLICIT INPUTS:	None.
**
**  IMPLICIT OUTPUTS:	None.
**
**  COMPLETION CODES:
**
**	SS$_BADCONTEXT - SSL context is bad
**
**
**  SIDE EFFECTS:   	None.
**
**--
*/
unsigned int netlib_ssl_socket (struct CTX **xctx, void **xsocket,
				void **xssl) {

    int argc;
    struct CTX *ctx;
    unsigned int aststat, status;

    SETARGCOUNT(argc);
    if (argc < 3) return SS$_INSFARG;
    if (xsocket == 0 || xssl == 0) return SS$_BADPARAM;
    if (*xsocket == 0 || *xssl == 0) return SS$_BADPARAM;

    BLOCK_ASTS(aststat);
    if (netlib_ssl_efn == 0xffffffff) {
    	status = lib$get_ef(&netlib_ssl_efn);
    	if (!OK(status)) {
    	    UNBLOCK_ASTS(aststat);
    	    return status;
    	}
    }
    UNBLOCK_ASTS(aststat);

    status = netlib___alloc_ctx(&ctx, SPECCTX_SIZE);
    if (!OK(status)) return status;

    ctx->spec_socket = *xsocket;

    status = SS$_INSFMEM;
    if ((ctx->spec_inbio = BIO_new(BIO_s_mem())) != 0) {
	if ((ctx->spec_outbio = BIO_new(BIO_s_mem())) != 0) {
	    BIO_set_callback(ctx->spec_outbio, outbio_callback);
	    BIO_set_callback_arg(ctx->spec_outbio, ctx);
	    if ((ctx->spec_ssl = SSL_new(*xssl)) != 0) {
	    	SSL_set_bio(ctx->spec_ssl, ctx->spec_inbio, ctx->spec_outbio);

	    	ctx->spec_data.dsc$w_length = 0;
	    	ctx->spec_data.dsc$b_dtype = DSC$K_DTYPE_T;
	    	ctx->spec_data.dsc$b_class = DSC$K_CLASS_S;
	    	ctx->spec_data.dsc$a_pointer = malloc(BUF_MAX);
	    	if (ctx->spec_data.dsc$a_pointer != 0) {
		    status = SS$_NORMAL;
	    	}
	    } else {
	    	status = SS$_BADCONTEXT;
	    }
	}
    }

    if (!OK(status)) {
	if (ctx->spec_inbio != 0) BIO_free(ctx->spec_inbio);
	if (ctx->spec_outbio != 0) BIO_free(ctx->spec_outbio);
	if (ctx->spec_ssl != 0) SSL_free(ctx->spec_ssl);
	if (ctx->spec_data.dsc$a_pointer != 0)
	    free(ctx->spec_data.dsc$a_pointer);
	netlib___free_ctx(ctx);
    } else {
	*xctx = ctx;
    }
    return status;
} /* netlib_ssl_socket */

#if 0
/*
**++
**  ROUTINE:	netlib_ssl_accept
**
**  FUNCTIONAL DESCRIPTION:
**
**  	Server side that accepts and incoming SSL connection.
**
**  RETURNS:	cond_value, longword (unsigned), write only, by value
**
**  PROTOTYPE:
**
**  	tbs
**
**  IMPLICIT INPUTS:	None.
**
**  IMPLICIT OUTPUTS:	None.
**
**  COMPLETION CODES:
**
**
**  SIDE EFFECTS:   	None.
**
**--
*/
unsigned int netlib_ssl_accept (struct CTX **xctx,
			        struct NETLIBIOSBDEF *iosb,
			        void (*astadr)(), void *astprm) {

    struct CTX *ctx;
    unsigned int status;
    int argc, *argv;

    VERIFY_CTX(xctx, ctx);
    SETARGCOUNT(argc);

    if (argc < 1) return SS$_INSFARG;

    if (argc > 2 && astadr != 0) {
	struct IOR *ior;
	GET_IOR(ior, ctx, iosb, astadr, (argc > 3) ? astprm : 0);
	argv = malloc(1 + 1);
	if (argv == 0) {
	    status = SS$_INSFMEM;
	} else {
	    argv[0] = 1;
	    argv[1] = (int) ctx->spec_ssl;
	    ior->spec_argv = argv;
	    ior->spec_call = SSL_accept;
	    //status = sys$dclast(io_perform, ior, 0);
	}
	if (!OK(status)) {
	    if (ior->spec_argv != 0) free(ior->spec_argv);
	    FREE_IOR(ior);
	}
    } else {
	// we don't do anything here yet...how are we going to handle this?
    }

    return status;
} /* netlib_ssl_accept */
#endif

/*
**++
**  ROUTINE:	netlib_ssl_connect
**
**  FUNCTIONAL DESCRIPTION:
**
**  	Client side routine that makes an outgoing SSL connection.
**
**  RETURNS:	cond_value, longword (unsigned), write only, by value
**
**  PROTOTYPE:
**
**  	tbs
**
**  IMPLICIT INPUTS:	None.
**
**  IMPLICIT OUTPUTS:	None.
**
**  COMPLETION CODES:
**
**
**  SIDE EFFECTS:   	None.
**
**--
*/
unsigned int netlib_ssl_connect (struct CTX **xctx, TIME *timeout,
			         struct NETLIBIOSBDEF *iosb,
			         void (*astadr)(), void *astprm) {

    
    struct CTX *ctx;
    unsigned int status;
    int argc, *argv;

    VERIFY_CTX(xctx, ctx);
    SETARGCOUNT(argc);

    if (argc < 1) return SS$_INSFARG;

    if (argc > 3 && astadr != 0) {
	struct IOR *ior;
	GET_IOR(ior, ctx, iosb, astadr, (argc > 4) ? astprm : 0);
	ior->spec_argc = 1;
	ior->spec_argv(0).address = ctx->spec_ssl;
	ior->spec_call = SSL_connect;
	status = sys$dclast(io_perform, ior, 0);
	if (!OK(status)) FREE_IOR(ior);
    } else {
	// we don't do anything here yet...how are we going to handle this?
    }

    // SSL timeouts need to be handled by ourselves...the netlib routines
    // underneatch should likely be called without...

    return status;

} /* netlib_ssl_connect */

/*
**++
**  ROUTINE:	netlib_ssl_shutdown
**
**  FUNCTIONAL DESCRIPTION:
**
**  	Shutdown an SSL connection.  This does not close the underlying
**  NETLIB socket.
**
**  RETURNS:	cond_value, longword (unsigned), write only, by value
**
**  PROTOTYPE:
**
**  	tbs
**
**  IMPLICIT INPUTS:	None.
**
**  IMPLICIT OUTPUTS:	None.
**
**  COMPLETION CODES:
**
**
**  SIDE EFFECTS:   	None.
**
**--
*/
unsigned int netlib_ssl_shutdown (struct CTX **xctx,
				  struct NETLIBIOSBDEF *iosb,
				  void (*astadr)(), void *astprm) {

    struct CTX *ctx;
    unsigned int status;
    int argc, *argv;

    VERIFY_CTX(xctx, ctx);
    SETARGCOUNT(argc);

    if (argc < 1) return SS$_INSFARG;

    if (argc > 3 && astadr != 0) {
	struct IOR *ior;
	GET_IOR(ior, ctx, iosb, astadr, (argc > 4) ? astprm : 0);
	ior->spec_argc = 1;
	ior->spec_argv(0).address = ctx->spec_ssl;
	ior->spec_call = SSL_shutdown;
	status = sys$dclast(io_perform, ior, 0);
	if (!OK(status)) FREE_IOR(ior);
    } else {
	// we don't do anything here yet...how are we going to handle this?
    }

    return status;
} /* netlib_ssl_shutdown */

#if 0
unsigned int netlib_ssl_write (struct CTX **xctx, struct dsc$descriptor *dsc,
			       struct NETLIBIOSBDEF *iosb,
			       void (*astadr)(), void *astprm) {

    struct CTX *ctx;
    void *bufptr;
    int status;
    unsigned short buflen;
    int argc;

    VERIFY_CTX(xctx, ctx);
    SETARGCOUNT(argc);

    status = lib$analyze_sdesc(dsc, &buflen, &bufptr);
    if (!OK(status)) return status;

    if (argc > 3) {
	struct IOR *ior;
	GET_IOR(ior, ctx, iosb, astadr, (argc > 4) ? astprm : 0);
	ctx->spec_bptr = malloc(buflen);
	if (ctx->spec_bptr != 0) {
	    memcpy(ctx->spec_bptr, bufptr, buflen);
	    ctx->spec_blen = buflen;
	    argv = malloc(3 + 1);
	    if (argv != 0) {
	    	argv[0] = 3;
	    	argv[1] = ctx->spec_ssl;
	    	argv[2] = bufptr;
	    	argv[3] = buflen;
	    	ior->spec_argv = argv;
	    	ior->spec_call = SSL_write;
	    	status = sys$dclast(io_perform, ior, 0);
	    } else {
	    	status = SS$_INSFMEM;
	    }
	} else {
	    status = SS$_INSFMEM;
	}
	if (!OK(status)) {
	    if (ior->spec_bptr != 0) free(ior->spec_bptr);
	    if (ior->spec_argv != 0) free(ior->spec_argv);
	    FREE_IOR(ior);
	}
    } else {
	// not handling sychronous stuff right now...
    }
}
#endif

static unsigned int io_perform (struct IOR *ior) {

    int ret, status;
    struct CTX *ctx = ior->ctx;

    if (OK(ior->iosb.iosb_w_status)) {
    	ret = lib$callg(ior->arg, ior->spec_call);
    	status = SSL_get_error(ctx->spec_ssl, ret);
    	if (status == SSL_ERROR_WANT_READ) {
	    status = netlib_read(&ctx->spec_socket, &ctx->spec_data, 0, 0,
			     	 0, 0, &ior->iosb, io_read, ior);
	    if (OK(status)) return SS$_NORMAL;
    	} else {
	    if (status == SSL_ERROR_WANT_WRITE) {
	    	ret = BIO_read(ctx->spec_outbio, ctx->spec_data.dsc$a_pointer,
			       BUF_MAX);
	    	if (ret > 0) {
	    	    ctx->spec_data.dsc$w_length = ret;
	    	    status = netlib_write(&ctx->spec_socket, &ctx->spec_data,
					  0, 0, &ior->iosb, io_write, ior);
		    if (OK(status)) return SS$_NORMAL;
	    	} else {
		    /*
		    ** We should not arrive in here, so it should be
		    ** considered a catastrophic failure if we do.  Well, at
		    ** least time to log an issue in Github ;-)
		    */
		    status = SS$_SSFAIL;
	    	}
	    } else if (status == SSL_ERROR_NONE) {
	    	status = SS$_NORMAL;
    	    } else {
printf("SSL_ERROR_WANT_? = %d\n", status);
ERR_print_errors_fp(stdout);
	    	// setup the iosb status
	    	// set the iosb status to the length of what was supposed to be
	    	//  written, or if incomplete?  How can we track that?
	    	// maybe use the extra fields of the iosb to report how much ssl
	    	//  traffic read/write was done...
	    }
	}
	ior->iosb.iosb_w_status = status;
    }

    if (ior->iosbp != 0) netlib___cvt_iosb(ior->iosbp, &ior->iosb);
    if (ior->astadr != 0) (*(ior->astadr))(ior->astprm);
    FREE_IOR(ior);

    return SS$_NORMAL;
} /* io_perform */

static unsigned int io_read (struct IOR *ior) {

    char *ptr;
    int size, status;
    struct CTX *ctx = ior->ctx;

    if (OK(ior->iosb.iosb_w_status)) {
	status = BIO_write(ctx->spec_inbio, ctx->spec_data.dsc$a_pointer,
			   ior->iosb.iosb_w_count);
	if (status > 0) {
		status = SS$_NORMAL;
	} else {
	    /*
	    ** According to the SSL documentation the only thing that
	    ** can cause a BIO_s_mem to fail is a lack of VM.
	    */
	    status = SS$_INSFMEM;
        }
	ior->iosb.iosb_w_status = status;
    }

    sys$dclast(io_perform, ior, 0);
    return SS$_NORMAL;
} /* io_read */

static unsigned int io_write (struct IOR *ior) {

    int status;
    struct CTX *ctx = ior->ctx;

    if (OK(ior->iosb.iosb_w_status)) {
	ctx->spec_flags |= IOR_M_COMPLETE;
    }

    sys$dclast(io_perform, ior, 0);

    return SS$_NORMAL;
} /* io_write */

static long outbio_callback (BIO *b, int oper, const char *argp, int argi,
			     long argl, long retvalue) {

    struct CTX *ctx = (struct CTX *)BIO_get_callback_arg(b);

    switch (oper) {
    default:
	break;

    case BIO_CB_WRITE|BIO_CB_RETURN:
	if (ctx->spec_flags & IOR_M_COMPLETE) {
	    ctx->spec_flags &= ~IOR_M_COMPLETE;
	    BIO_reset(b);
	} else {
	    BIO_set_retry_write(b);
	    retvalue = -1;
	}
	break;

    }

    return retvalue;
} /* outbio_callback */

/*

Translate SSL status codes to OpenVMS ones...

Should we store these somewhere and provide an interface to fetch the
full status via a netlib_ssl_xxx routine?  This way you could find out what
was really going on.  Although, we still need to document the kind of
errors that occur when processing the errors...

*/
int netlib___cvt_status(int err,
			...) {

    va_list argptr;
    int argc;
    int _errno = EVMSERR, _vaxc$errno = SS$_NORMAL;
    int lib, func, reason, status;

    SETARGCOUNT(argc);

    if (argc > 1) {
	va_start(argptr, err);
	_errno = va_arg(argptr, int);
	if (argc > 2) _vaxc$errno = va_arg(argptr, int);
	va_end(argptr);
    }

    lib = ERR_GET_LIB(err);
    func = ERR_GET_FUNC(err);
    reason = ERR_GET_REASON(err);

    switch (lib) {
    case ERR_LIB_SYS:
	status = _vaxc$errno;
	break;

    case ERR_LIB_X509:
	switch (reason) {
	case X509_R_INVALID_DIRECTORY:
	    status = RMS$_DNF;
	    break;
	case X509_R_KEY_TYPE_MISMATCH:
	case X509_R_KEY_VALUES_MISMATCH:
	    status = RMS$_KEY_MISMATCH;
	    break;
	case X509_R_UNSUPPORTED_ALGORITHM:
	    status = SS$_UNSUPPORTED;
	    break;
	default:
	    status = SS$_BADCHECKSUM;
	    break;
	}
	break;
    }

    return status;
}
