.PHONY: run help

# Vérification des variables obligatoires
CHECK_SSH_KEY:
ifndef SSH_KEY
	$(error SSH_KEY doit être défini. Usage: make run SSH_KEY=/chemin/vers/cle)
endif

run: CHECK_SSH_KEY
	@./run.sh --ssh-key $(SSH_KEY)

help:
	@echo "Options obligatoires:"
	@echo "  SSH_KEY       Chemin vers la clé SSH"
	@echo ""
	@echo "Usage:"
	@echo "  make run SSH_KEY=/chemin/vers/cle"
	@echo "  make help"