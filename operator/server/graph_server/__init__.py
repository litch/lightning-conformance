import configparser
import time

def load_config(name, count=0):
    config = configparser.ConfigParser()

    max_retries = 5
    try:
        config.read(f"./config/{name}.ini")
        if len (config.sections()) == 0:
            raise Exception("No config sections found")
        return config
    except Exception as e:
        print(f"Failed to read config for '{name}', retry {count} of {max_retries}")
        time.sleep(2)
        if count < max_retries:
            load_config(name, count+1)
        else:
            print("Failed to read config, exiting")
            exit(1)