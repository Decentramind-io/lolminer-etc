# Сборка образа Docker для платформы Decentramind.io
на примере майнера lolMiner

#### Предварительные условия 
* Ubuntu 20.04 или другая ОС/дистрибутив с поддержкой Docker
* Учетная запись платформы **Decentramind.io**

#### Ожидаемый результат
* Пользовательское приложение (в этом примере - lolMiner), обернутое в контейнер docker и готовое к запуску на мощностях платформы **Decentramind.io**. 
* Образ приложения размещен в репозитории **Decentramind.io**.

#### Установка и настройка Docker
Установим docker в соответствии с [официальной инструкцией по установке](https://docs.docker.com/engine/install/ubuntu/).
Подключим его к репозиторию образов Decentramind.io:

```
sudo docker login https://registry.decentramind.io/v2/
```
Появится запрос на ввод логина и пароля, нужно ввести логин и пароль в системе **Decentramind.io**.

#### Создание Dockerfile
Опишем создаваемый образ в терминах ```Dockerfile```. Для этого выполним команды:

```
mkdir ~/docker-calcpi
cd ~/docker-calcpi/
nano Dockerfile
```

Примерное содержимое ```Dockerfile``` может быть таким:

```
# базовый образ для создаваемого образа, CUDA необходима для работы майнера
FROM nvidia/cuda:10.1-base

# обновление ключей для сервера deb-пакетов nvidia
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC

# установка необходимых пакетов
RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade jq wget

# скачивание lolMiner, разархивирование и удаление оригинального архива
RUN wget https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.68/lolMiner_v1.68_Lin64.tar.gz && tar -xf lol* && mv 1.68 lolMiner && rm lolMiner_v1.68_Lin64.tar.gz

# добавление стартового скрипта и выставление разрешения на запуск
ADD start.sh /
RUN chmod +x start.sh

# указываем, что будет запущено при запуске контейнера
ENTRYPOINT ["/start.sh"]

```
Как можно видеть выше, этот ```Dockerfile``` описывает контейнер на базе контейнера Nvidia CUDA 10.1, в который добавлено приложение lolMiner.

#### Создание стартового скрипта 
В задачу (контейнер) на платформе **Decentramind.io** можно передать произвольные параметры в виде текста. Для получения параметров используется переменная среды ```$BASE64_ARGS_VAR```, данные в которой закодированы в Base64 (со стороны API данные передаются в открытом, незакодированном виде, см. [Decentramind.io API](https://github.com/Decentramind-io/API-SDK/blob/main/megamind.api.v1.public.json)). Для примера примем, что создаваемый контейнер ожидает увидеть в параметрах задачи адрес кошелька Ethereum Classic для майнинга и имя воркера (worker). Примем также, что параметры эти должны быть переданы в виде объекта json вида ``` { "wallet": "<wallet address>", "worker_name": "<worker name>"} ```. Создадим стартовый скрипт ```start.sh```, который получает из параметров задачи кошелек для майнинга и имя воркера, вызвав ```nano start.sh```. В простейшем случае стартовый скрипт должен содержать следующий текст:

```
#!/bin/bash

# раскодирование base64
UNB64=$(echo $BASE64_ARGS_VAR | base64 --decode)

# получение из json полей wallet и worker_name
WALLET=$(jq -r '.wallet' <<< $UNB64)
WORKER=$(jq -r '.worker_name' <<< $UNB64)

# если кошелек не передан, то дальнейшая работа бессмысленна
if [[ "$WALLET" == "null" || ( -z "$WALLET") ]];
	then
		echo 'empty wallet supplied'
		exit
	fi

# если имя воркера не передано, можно подставить имя задачи в рамках платформы Decentramind.io, оно содержится в переменной $TASKNAME
if [[ "$WORKER" == "null" || ( -z "$WORKER") ]];
	then
		WORKER=$TASKNAME
	fi

# запуск майнера в режиме Ethereum Classic с указанными параметрами
/lolMiner/lolMiner --algo ETCHASH --pool etc.2miners.com:1010 --user $WALLET --worker $WORKER

```

#### Создание образа
Соберем образ командой 
```
sudo docker build -t registry.decentramind.io/lolminer:1 .
```
Здесь мы собираем образ в текущей папке и присваиваем ему тег registry.decentramind.io/lolminer:1, где ```registry.decentramind.io/``` - обязательная часть (адрес docker registry для сохранения образа), ```lolminer``` - имя образа (выбирается произвольно), ```1``` - метка версии (выбирается произвольно, один образ может содержать несколько версий).

#### Выгрузка образа в репозиторий
Выгрузим образ в репозиторий **Decentramind.io**:
```
sudo docker push registry.decentramind.io/lolminer:1
```
С этого момента образ ```registry.decentramind.io/lolminer:1``` доступен для запуска на платформе **Decentramind.io**. Для запуска и контроля задач нужно использовать [Decentramind.io API](https://github.com/Decentramind-io/API-SDK/blob/main/megamind.api.v1.public.json).