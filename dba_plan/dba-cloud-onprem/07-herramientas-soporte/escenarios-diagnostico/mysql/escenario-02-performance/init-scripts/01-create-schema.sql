-- Script de Inicialización - Escenario MySQL Performance
-- Base de datos: edutech_db

USE edutech_db;

-- Crear tabla de usuarios
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    user_type ENUM('student', 'instructor', 'admin') NOT NULL,
    registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    profile_data JSON
);

-- Crear tabla de categorías de cursos
CREATE TABLE course_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_category_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES course_categories(category_id)
);

-- Crear tabla de cursos (SIN ÍNDICES OPTIMIZADOS - PROBLEMA)
CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    instructor_id INT NOT NULL,
    category_id INT NOT NULL,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced') NOT NULL,
    duration_hours INT NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_published BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    tags JSON,
    course_content TEXT,
    -- PROBLEMA: Solo índice de primary key, faltan índices importantes
    FOREIGN KEY (instructor_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES course_categories(category_id)
);

-- Crear tabla de lecciones (SIN ÍNDICES OPTIMIZADOS)
CREATE TABLE lessons (
    lesson_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    lesson_title VARCHAR(200) NOT NULL,
    lesson_content TEXT,
    lesson_order INT NOT NULL,
    duration_minutes INT NOT NULL,
    video_url VARCHAR(500),
    is_free BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- PROBLEMA: Falta índice en course_id
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);

-- Crear tabla de inscripciones (SIN ÍNDICES OPTIMIZADOS)
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enrollment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    completion_date DATETIME NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    last_accessed DATETIME,
    is_completed BOOLEAN DEFAULT FALSE,
    payment_status ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',
    -- PROBLEMA: Faltan índices en student_id, course_id
    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    UNIQUE KEY unique_enrollment (student_id, course_id)
);

-- Crear tabla de progreso de estudiantes (TABLA MÁS PROBLEMÁTICA)
CREATE TABLE student_progress (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    enrollment_id INT NOT NULL,
    lesson_id INT NOT NULL,
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    time_spent_minutes INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    quiz_score DECIMAL(5,2) NULL,
    notes TEXT,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- PROBLEMA: Sin índices en enrollment_id, lesson_id - causará table scans
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id)
);

-- Crear tabla de reviews (para búsquedas)
CREATE TABLE course_reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    student_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_approved BOOLEAN DEFAULT TRUE,
    -- PROBLEMA: Falta índice en course_id para agregaciones
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (student_id) REFERENCES users(user_id)
);

-- Crear tabla de estadísticas de cursos (para dashboard)
CREATE TABLE course_stats (
    stat_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    total_enrollments INT DEFAULT 0,
    total_completions INT DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_revenue DECIMAL(12,2) DEFAULT 0.00,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- PROBLEMA: Sin índice en course_id
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

-- Crear tabla de logs de actividad (crece rápidamente)
CREATE TABLE activity_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- PROBLEMA: Sin índices para consultas por usuario o fecha
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Insertar categorías básicas
INSERT INTO course_categories (category_name, description) VALUES
('Programming', 'Software development and programming languages'),
('Data Science', 'Data analysis, machine learning, and statistics'),
('Web Development', 'Frontend and backend web development'),
('Mobile Development', 'iOS and Android app development'),
('DevOps', 'Development operations and infrastructure'),
('Design', 'UI/UX design and graphic design'),
('Business', 'Business skills and entrepreneurship'),
('Marketing', 'Digital marketing and social media');

-- Crear vista problemática para dashboard (SIN OPTIMIZACIÓN)
CREATE VIEW dashboard_course_summary AS
SELECT 
    c.course_id,
    c.title,
    c.instructor_id,
    u.first_name AS instructor_name,
    c.category_id,
    cc.category_name,
    c.difficulty_level,
    c.price,
    -- PROBLEMA: Subconsultas que causan N+1 queries
    (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.course_id) AS total_enrollments,
    (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.course_id AND e.is_completed = TRUE) AS total_completions,
    (SELECT AVG(rating) FROM course_reviews cr WHERE cr.course_id = c.course_id) AS avg_rating,
    (SELECT COUNT(*) FROM course_reviews cr WHERE cr.course_id = c.course_id) AS total_reviews,
    c.created_at
FROM courses c
JOIN users u ON c.instructor_id = u.user_id
JOIN course_categories cc ON c.category_id = cc.category_id
WHERE c.is_published = TRUE;

-- Crear procedimiento almacenado problemático para reportes
DELIMITER //
CREATE PROCEDURE GetStudentProgressReport(IN student_id_param INT)
BEGIN
    -- PROBLEMA: Query muy ineficiente con múltiples JOINs sin índices
    SELECT 
        c.title AS course_title,
        c.difficulty_level,
        e.enrollment_date,
        e.progress_percentage,
        e.is_completed,
        COUNT(sp.progress_id) AS lessons_started,
        COUNT(CASE WHEN sp.is_completed = TRUE THEN 1 END) AS lessons_completed,
        SUM(sp.time_spent_minutes) AS total_time_spent,
        AVG(sp.quiz_score) AS average_quiz_score
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    LEFT JOIN student_progress sp ON e.enrollment_id = sp.enrollment_id
    WHERE e.student_id = student_id_param
    GROUP BY c.course_id, c.title, c.difficulty_level, e.enrollment_date, e.progress_percentage, e.is_completed
    ORDER BY e.enrollment_date DESC;
END //
DELIMITER ;

-- Crear función problemática para cálculo de progreso
DELIMITER //
CREATE FUNCTION CalculateCourseProgress(enrollment_id_param INT) 
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_lessons INT DEFAULT 0;
    DECLARE completed_lessons INT DEFAULT 0;
    DECLARE progress_pct DECIMAL(5,2) DEFAULT 0.00;
    
    -- PROBLEMA: Múltiples queries sin índices optimizados
    SELECT COUNT(*) INTO total_lessons
    FROM lessons l
    JOIN enrollments e ON l.course_id = e.course_id
    WHERE e.enrollment_id = enrollment_id_param;
    
    SELECT COUNT(*) INTO completed_lessons
    FROM student_progress sp
    WHERE sp.enrollment_id = enrollment_id_param 
    AND sp.is_completed = TRUE;
    
    IF total_lessons > 0 THEN
        SET progress_pct = (completed_lessons / total_lessons) * 100;
    END IF;
    
    RETURN progress_pct;
END //
DELIMITER ;

-- Crear trigger que actualiza estadísticas (puede causar locks)
DELIMITER //
CREATE TRIGGER update_course_stats_after_enrollment
AFTER INSERT ON enrollments
FOR EACH ROW
BEGIN
    -- PROBLEMA: Trigger que hace queries adicionales
    INSERT INTO course_stats (course_id, total_enrollments, last_updated)
    VALUES (NEW.course_id, 1, NOW())
    ON DUPLICATE KEY UPDATE 
        total_enrollments = total_enrollments + 1,
        last_updated = NOW();
END //
DELIMITER ;

-- Mostrar estructura creada
SHOW TABLES;

-- Mostrar que no hay índices optimizados (parte del problema)
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'edutech_db' 
AND TABLE_NAME IN ('courses', 'enrollments', 'student_progress', 'lessons')
ORDER BY TABLE_NAME, INDEX_NAME;
