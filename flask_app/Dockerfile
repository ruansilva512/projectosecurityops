FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install Flask requests # 'requests' is not strictly needed for this basic app but good to keep if you plan API calls
EXPOSE 5000
CMD ["python", "app.py"]