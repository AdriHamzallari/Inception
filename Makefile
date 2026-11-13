COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

DATA_DIR = /home/ahamzall/data
WP_DATA = $(DATA_DIR)/wordpress
DB_DATA = $(DATA_DIR)/mariadb


all:
	mkdir -p $(WP_DATA)
	mkdir -p $(DB_DATA)
	$(COMPOSE) up -d --build


up:
	$(COMPOSE) up -d


down:
	$(COMPOSE) down


stop:
	$(COMPOSE) stop


start:
	$(COMPOSE) start


clean:
	$(COMPOSE) down


fclean:
	$(COMPOSE) down --volumes --rmi all
	sudo rm -rf $(WP_DATA)
	sudo rm -rf $(DB_DATA)


re: fclean all


ps:
	$(COMPOSE) ps


logs:
	$(COMPOSE) logs


.PHONY: all up down stop start clean fclean re ps logs