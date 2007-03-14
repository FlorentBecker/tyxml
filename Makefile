include Makefile.config

ifeq "$(OCAMLDUCE)" "YES"
DUCEFILES=server/ocsigenduce.cmi server/ocsigenduce.cma \
	server/xhtml1_strict.cmi
DUCEEXAMPLES=modules/ocamlduce/exampleduce.cmo
else
DUCEFILES=
DUCEEXAMPLES=
endif



INSTALL = install
REPS = baselib lwt xmlp4 http server modules
CAMLDOC = $(OCAMLFIND) ocamldoc $(LIB)
TOINSTALL = modules/tutorial.cmo modules/tutorial.cmi modules/monitoring.cmo server/parseconfig.cmi server/ocsigen.cmi server/ocsigenmod.cma server/staticmod.cmi server/staticmod.cmo server/ocsigenboxes.cmi xmlp4/ohl-xhtml/xHTML.cmi xmlp4/ohl-xhtml/xML.cmi xmlp4/ohl-xhtml/xhtml.cma xmlp4/xhtmltypes.cmi xmlp4/simplexmlparser.cmi xmlp4/xhtmlsyntax.cma META lwt/lwt.cmi lwt/lwt_unix.cmi server/preemptive.cmi http/predefined_senders.cmi baselib/messages.cmi $(DUCEFILES)
EXAMPLES = modules/tutorial.cmo modules/tutorial.cmi modules/monitoring.cmo $(DUCEEXAMPLES)
PP = -pp "camlp4o ./lib/xhtmlsyntax.cma -loc loc"

all: $(REPS)

.PHONY: $(REPS) clean


baselib:
#	$(MAKE) -C baselib depend
	$(MAKE) -C baselib all

lwt:
#	$(MAKE) -C lwt depend
	$(MAKE) -C lwt all

xmlp4:
	touch xmlp4/.depend
	$(MAKE) -C xmlp4 depend
	$(MAKE) -C xmlp4 all

http :
#	$(MAKE) -C http depend
	$(MAKE) -C http all

modules:
	$(MAKE) -C modules all

server:
#	$(MAKE) -C server depend
	$(MAKE) -C server all

doc:
	$(CAMLDOC) $(PP) -package ssl -I lib -d doc/lwt -html lwt/lwt.mli lwt/lwt_unix.mli
	$(CAMLDOC) $(PP) -package netstring -I lib -I `$(CAMLP4) -where` -d doc/oc -html server/ocsigen.mli server/extensions.mli server/parseconfig.mli xmlp4/oldocaml/simplexmlparser.mli xmlp4/ohl-xhtml/xHTML.mli server/ocsigenboxes.mli baselib/messages.ml http/predefined_senders.mli

clean:
	-@for i in $(REPS) ; do touch "$$i"/.depend ; done
	-@for i in $(REPS) ; do $(MAKE) -C $$i clean ; done
	-rm -f lib/* *~
	-rm -f bin/* *~

depend: xmlp4
	touch lwt/depend
	@for i in $(REPS) ; do touch "$$i"/.depend; $(MAKE) -C $$i depend ; done


.PHONY: install fullinstall doc
install:
	mkdir -p $(PREFIX)/$(MODULEINSTALLDIR)
	mkdir -p $(PREFIX)/$(EXAMPLESINSTALLDIR)
	$(MAKE) -C server install
	cat META.in | sed s/_VERSION_/`head -n 1 VERSION`/ > META
	$(OCAMLFIND) install $(OCSIGENNAME) -destdir "$(PREFIX)/$(MODULEINSTALLDIR)" $(TOINSTALL)
	install -m 644 $(EXAMPLES) $(PREFIX)/$(EXAMPLESINSTALLDIR)
	-rm META


fullinstall: doc install
	mkdir -p $(PREFIX)/$(CONFIGDIR)
	mkdir -p $(PREFIX)/$(STATICPAGESDIR)
	-mv $(PREFIX)/$(CONFIGDIR)/ocsigen.conf $(PREFIX)/$(CONFIGDIR)/ocsigen.conf.old
	cat files/ocsigen.conf \
	| sed s%_LOGDIR_%$(LOGDIR)%g \
	| sed s%_STATICPAGESDIR_%$(STATICPAGESDIR)%g \
	| sed s%_UP_%$(UPLOADDIR)%g \
	| sed s%_OCSIGENUSER_%$(OCSIGENUSER)%g \
	| sed s%_OCSIGENGROUP_%$(OCSIGENGROUP)%g \
	| sed s%_MODULEINSTALLDIR_%$(MODULEINSTALLDIR)/$(OCSIGENNAME)%g \
	> $(PREFIX)/$(CONFIGDIR)/ocsigen.conf
	-mv $(PREFIX)/$(CONFIGDIR)/mime.types $(PREFIX)/$(CONFIGDIR)/mime.types.old
	cp -f files/mime.types $(PREFIX)/$(CONFIGDIR)
	mkdir -p $(PREFIX)/$(LOGDIR)
	$(CHOWN) -R $(OCSIGENUSER):$(OCSIGENGROUP) $(PREFIX)/$(LOGDIR)
	$(CHOWN) -R $(OCSIGENUSER):$(OCSIGENGROUP) $(PREFIX)/$(STATICPAGESDIR)
	chmod u+rwx $(PREFIX)/$(LOGDIR)
	chmod a+rx $(PREFIX)/$(CONFIGDIR)
	chmod a+r $(PREFIX)/$(CONFIGDIR)/ocsigen.conf
	chmod a+r $(PREFIX)/$(CONFIGDIR)/mime.types
	mkdir -p $(PREFIX)/$(DOCDIR)
	install -d -m 755 $(PREFIX)/$(DOCDIR)/lwt
	install -d -m 755 $(PREFIX)/$(DOCDIR)/oc
	-install -m 644 doc/* $(PREFIX)/$(DOCDIR)
	install -m 644 doc/lwt/* $(PREFIX)/$(DOCDIR)/lwt
	install -m 644 doc/oc/* $(PREFIX)/$(DOCDIR)/oc
	chmod a+rx $(PREFIX)/$(DOCDIR)
	chmod a+r $(PREFIX)/$(DOCDIR)/*
	[ -d /etc/logrotate.d ] && \
	 { mkdir -p ${PREFIX}/etc/logrotate.d \
	   cat files/logrotate.IN \
	   | sed s%LOGDIR%$(LOGDIR)%g \
	   | sed s%USER%$(OCSIGENUSER)%g \
	   | sed s%GROUP%$(OCSIGENGROUP)%g \
	  > $(PREFIX)/etc/logrotate.d/$(OCSIGENNAME); }
	install -d -m 755 $(PREFIX)/$(MANDIR)
	install -m 644 files/ocsigen.1 $(PREFIX)/$(MANDIR)


.PHONY: uninstall fulluninstall
uninstall:
	$(MAKE) -C server uninstall
	$(OCAMLFIND) remove $(OCSIGENNAME) -destdir "$(PREFIX)/$(MODULEINSTALLDIR)"

fulluninstall: uninstall
# dangerous
#	rm -f $(CONFIGDIR)/ocsigen.conf
#	rm -f $(LOGDIR)/ocsigen.log
#	rm -rf $(MODULEINSTALLDIR)

