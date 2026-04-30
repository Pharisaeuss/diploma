import os
import boto3
import streamlit as st
import psycopg2
import pandas as pd
from datetime import datetime, timedelta

# --- КОНФІГУРАЦІЯ СЕРЕДОВИЩА ---
ENV = os.environ.get('ENV', 'dev')
AWS_REGION = os.environ.get('AWS_DEFAULT_REGION', 'eu-central-1')

# Ідентифікатори ресурсів (передаються через Ansible / Systemd)
ASG_NAME = os.environ.get('ASG_NAME', f'app-asg-{ENV}')
DB_IDENTIFIER = os.environ.get('DB_IDENTIFIER', f'streamlit-db-{ENV}')
ALB_SUFFIX = os.environ.get('ALB_SUFFIX', '') # Змінна має містити ARN суфікс ALB

st.set_page_config(page_title=f"DevOps Dashboard ({ENV.upper()})", layout="wide")
st.title("📊 Комплексний моніторинг інфраструктури (SRE Standards)")
st.markdown("Візуалізація «Чотирьох золотих сигналів» та бізнес-метрик застосунку.")

# --- ФУНКЦІЇ ДОСТУПУ ДО AWS ---
@st.cache_data(ttl=300)
def get_ssm_secret(parameter_name, with_decryption=False):
    try:
        ssm = boto3.client('ssm', region_name=AWS_REGION)
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=with_decryption)
        return response['Parameter']['Value']
    except Exception as e:
        st.error(f"Помилка SSM ({parameter_name}): {e}")
        return None

def get_cloudwatch_metrics(metric_name, namespace, dimensions, stat="Average", period=3600):
    """Отримання телеметрії з AWS CloudWatch"""
    try:
        cw = boto3.client('cloudwatch', region_name=AWS_REGION)
        response = cw.get_metric_statistics(
            Namespace=namespace,
            MetricName=metric_name,
            Dimensions=dimensions,
            StartTime=datetime.utcnow() - timedelta(hours=12),
            EndTime=datetime.utcnow(),
            Period=period,
            Statistics=[stat]
        )
        datapoints = response.get('Datapoints', [])
        if not datapoints:
            return pd.DataFrame()
        
        df = pd.DataFrame(datapoints)
        df = df.sort_values(by='Timestamp')
        df['Timestamp'] = pd.to_datetime(df['Timestamp']).dt.strftime('%H:%M')
        return df.set_index('Timestamp')[stat]
    except Exception as e:
        return pd.DataFrame()

# --- ПІДКЛЮЧЕННЯ ДО БД ТА ІНІЦІАЛІЗАЦІЯ ---
db_host = get_ssm_secret(f'/{ENV}/database/endpoint')
db_name = get_ssm_secret(f'/{ENV}/database/name')
db_user = get_ssm_secret(f'/{ENV}/database/username')
db_pass = get_ssm_secret(f'/{ENV}/database/password', with_decryption=True)
ASG_NAME = get_ssm_secret(f'/{ENV}/app/asg_name')
DB_IDENTIFIER = get_ssm_secret(f'/{ENV}/app/db_identifier')
ALB_SUFFIX = get_ssm_secret(f'/{ENV}/app/alb_suffix')

def init_db_and_seed_data(conn):
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS solar_generation (
            id SERIAL PRIMARY KEY,
            record_date DATE DEFAULT CURRENT_DATE,
            region VARCHAR(50),
            energy_kwh FLOAT
        );
    """)
    cursor.execute("SELECT COUNT(*) FROM solar_generation;")
    if cursor.fetchone()[0] == 0:
        sample_data = [
            ('Vinnytsia', 120.5), ('Vinnytsia', 145.2), ('Vinnytsia', 98.4),
            ('Kyiv', 90.1), ('Kyiv', 110.0), ('Lviv', 85.5)
        ]
        cursor.executemany(
            "INSERT INTO solar_generation (region, energy_kwh) VALUES (%s, %s)", 
            sample_data
        )
        conn.commit()
    cursor.close()

# --- ІНТЕРФЕЙС: ІНФРАСТРУКТУРНІ МЕТРИКИ (FOUR GOLDEN SIGNALS) ---
st.subheader("☁️ Інфраструктурна телеметрія (AWS CloudWatch)")

col1, col2 = st.columns(2)

with col1:
    st.markdown("**1. Насиченість (Saturation): ASG Average CPU %**")
    cpu_data = get_cloudwatch_metrics('CPUUtilization', 'AWS/EC2', [{'Name': 'AutoScalingGroupName', 'Value': ASG_NAME}])
    if not cpu_data.empty:
        st.line_chart(cpu_data)
    else:
        st.info("Дані CPU недоступні.")

    if ALB_SUFFIX:
        st.markdown("**2. Затримка (Latency): ALB Target Response Time (s)**")
        latency_data = get_cloudwatch_metrics('TargetResponseTime', 'AWS/ApplicationELB', [{'Name': 'LoadBalancer', 'Value': ALB_SUFFIX}])
        if not latency_data.empty:
            st.line_chart(latency_data)
        else:
            st.info("Дані Latency недоступні.")
    else:
        st.warning("ALB_SUFFIX не задано. Метрики балансувальника вимкнено.")

with col2:
    st.markdown("**3. Насиченість БД (Saturation): RDS Active Connections**")
    db_conn_data = get_cloudwatch_metrics('DatabaseConnections', 'AWS/RDS', [{'Name': 'DBInstanceIdentifier', 'Value': DB_IDENTIFIER}], stat="Maximum")
    if not db_conn_data.empty:
        st.line_chart(db_conn_data)
    else:
        st.info("Дані підключень RDS недоступні.")

    if ALB_SUFFIX:
        st.markdown("**4. Помилки (Errors): ALB 5XX Target Error Count**")
        errors_data = get_cloudwatch_metrics('HTTPCode_Target_5XX_Count', 'AWS/ApplicationELB', [{'Name': 'LoadBalancer', 'Value': ALB_SUFFIX}], stat="Sum")
        if not errors_data.empty:
            st.bar_chart(errors_data)
        else:
            st.success("Помилок 5XX не виявлено 🎉")

# --- ІНТЕРФЕЙС: БІЗНЕС-ДАНІ ---
st.divider()
st.subheader("🗄️ Бізнес-аналітика (PostgreSQL RDS)")

try:
    conn = psycopg2.connect(host=db_host, user=db_user, password=db_pass, dbname=db_name)
    init_db_and_seed_data(conn)
    st.success(f"✅ З'єднання з БД `{db_name}` встановлено успішно.")
    
    df_db = pd.read_sql("SELECT region, SUM(energy_kwh) as total_generation FROM solar_generation GROUP BY region;", conn)
    st.markdown("**Сумарна генерація сонячної енергії по регіонах (кВт·год)**")
    st.bar_chart(df_db.set_index('region'))
    conn.close()
except Exception as e:
    st.error(f"Помилка бази даних: {e}")