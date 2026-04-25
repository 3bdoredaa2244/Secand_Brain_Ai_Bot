use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}

use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}

use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}

use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}


use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}

use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}
use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}

use axum::{
    routing::{get, post, put, delete},
    Router,
    Json,
    extract::{Path, State},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

// =====================
// Models
// =====================

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: String,
    title: String,
    completed: bool,
}

#[derive(Debug, Deserialize)]
struct CreateTask {
    title: String,
}

#[derive(Debug, Deserialize)]
struct UpdateTask {
    title: Option<String>,
    completed: Option<bool>,
}

// =====================
// App State
// =====================

type Db = Arc<Mutex<HashMap<String, Task>>>;

// =====================
// Handlers
// =====================

// GET /tasks
async fn get_tasks(State(db): State<Db>) -> Json<Vec<Task>> {
    let tasks = db.lock().unwrap();
    Json(tasks.values().cloned().collect())
}

// GET /tasks/:id
async fn get_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> Result<Json<Task>, StatusCode> {
    let tasks = db.lock().unwrap();

    match tasks.get(&id) {
        Some(task) => Ok(Json(task.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

// POST /tasks
async fn create_task(
    State(db): State<Db>,
    Json(payload): Json<CreateTask>,
) -> (StatusCode, Json<Task>) {
    let mut tasks = db.lock().unwrap();

    let task = Task {
        id: Uuid::new_v4().to_string(),
        title: payload.title,
        completed: false,
    };

    tasks.insert(task.id.clone(), task.clone());

    (StatusCode::CREATED, Json(task))
}

// PUT /tasks/:id
async fn update_task(
    Path(id): Path<String>,
    State(db): State<Db>,
    Json(payload): Json<UpdateTask>,
) -> Result<Json<Task>, StatusCode> {
    let mut tasks = db.lock().unwrap();

    if let Some(task) = tasks.get_mut(&id) {
        if let Some(title) = payload.title {
            task.title = title;
        }

        if let Some(completed) = payload.completed {
            task.completed = completed;
        }

        return Ok(Json(task.clone()));
    }

    Err(StatusCode::NOT_FOUND)
}

// DELETE /tasks/:id
async fn delete_task(
    Path(id): Path<String>,
    State(db): State<Db>,
) -> StatusCode {
    let mut tasks = db.lock().unwrap();

    if tasks.remove(&id).is_some() {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// =====================
// Main
// =====================

#[tokio::main]
async fn main() {
    let db: Db = Arc::new(Mutex::new(HashMap::new()));

    let app = Router::new()
        .route("/tasks", get(get_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .with_state(db);

    println!("🚀 Server running at http://localhost:3000");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}