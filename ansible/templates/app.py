import os
import boto3
import streamlit as st
import psycopg2

ENV = os.environ.get('ENV', 'dev')

def get_ssm_secret(parameter_name, with_decryption=False):
    """Функція для безпечного читання секретів з AWS SSM"""
    try:
        ssm = boto3.client('ssm')
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=with_decryption)
        return response['Parameter']['Value']
    except Exception as e:
        st.error(f"Помилка отримання параметра {parameter_name}: {e}")
        return None

db_host = get_ssm_secret(f'/{ENV}/database/endpoint')
db_name = get_ssm_secret(f'/{ENV}/database/name')
db_user = get_ssm_secret(f'/{ENV}/database/username')
db_pass = get_ssm_secret(f'/{ENV}/database/password', with_decryption=True)

try:
    conn = psycopg2.connect(
        host=db_host,
        user=db_user,
        password=db_pass,
        dbname=db_name
    )
    st.success(f"Успішно підключено до бази даних у середовищі {ENV.upper()}! 🎉")
except Exception as e:
    st.error("Не вдалося підключитися до бази даних.")