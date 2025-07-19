COMPOSE=docker compose -f docker-compose.yaml

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

# Profile operation
up-common:
	$(COMPOSE) --profile common up -d

down-common:
	$(COMPOSE) --profile common down

restart-common:
	$(COMPOSE) --profile common restart

up-media:
	$(COMPOSE) --profile media up -d

restart-media:
	$(COMPOSE) --profile media restart

down-media:
	$(COMPOSE) --profile media down

up-arr:
	$(COMPOSE) --profile arr up -d

restart-arr:
	$(COMPOSE) --profile arr restart

down-arr:
	$(COMPOSE) --profile arr down