#include <glad/glad.h>

const GLubyte *getString(GLenum name) { return glad_glGetString(name); }

void viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  glViewport(x, y, width, height);
}

void clearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
  glClearColor(red, green, blue, alpha);
}

void clear(GLbitfield mask) { glClear(mask); }

void genBuffers(GLsizei n, GLuint *buffers) { glad_glGenBuffers(n, buffers); }

void bindBuffer(GLenum target, GLuint buffer) {
  glad_glBindBuffer(target, buffer);
}

void bufferData(GLenum target, GLsizeiptr size, const GLvoid *data,
                GLenum usage) {
  glad_glBufferData(target, size, data, usage);
}

GLuint createShader(GLenum shaderType) {
  return glad_glCreateShader(shaderType);
}

void deleteShader(GLuint shader) { glad_glDeleteShader(shader); }

void shaderSource(GLuint shader, GLuint count, const GLchar *const *string) {
  glad_glShaderSource(shader, count, string, 0);
}

void compileShader(GLuint shader) { glad_glCompileShader(shader); }

void getShaderiv(GLuint shader, GLenum pname, GLint *params) {
  glad_glGetShaderiv(shader, pname, params);
}

void getShaderInfoLog(GLuint shader, GLsizei maxLength, GLsizei *length,
                      GLchar *infoLog) {
  glad_glGetShaderInfoLog(shader, maxLength, length, infoLog);
}

GLuint createProgram(void) { return glad_glCreateProgram(); }

void attachShader(GLuint program, GLuint shader) {
  glad_glAttachShader(program, shader);
}

void detachShader(GLuint program, GLuint shader) {
  glad_glAttachShader(program, shader);
}

void linkProgram(GLuint program) { glad_glLinkProgram(program); }

void getProgramiv(GLuint program, GLenum pname, GLint *params) {
  glad_glGetProgramiv(program, pname, params);
}

void getProgramInfoLog(GLuint program, GLsizei maxLength, GLsizei *length,
                       GLchar *infoLog) {
  glad_glGetProgramInfoLog(program, maxLength, length, infoLog);
}

GLint getUniformLocation(GLuint program, const GLchar *name) {
  return glad_glGetUniformLocation(program, name);
}

GLint getAttribLocation(GLuint program, const GLchar *name) {
  return glad_glGetAttribLocation(program, name);
}

void enableVertexAttribArray(GLuint index) {
  glad_glEnableVertexAttribArray(index);
}

void vertexAttribPointer(GLuint index, GLint size, GLenum type,
                         GLboolean normalized, GLsizei stride,
                         GLsizeiptr offset) {
  glad_glVertexAttribPointer(index, size, type, normalized, stride, offset);
}

void useProgram(GLuint program) { glad_glUseProgram(program); }

void uniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose,
                      const GLfloat *value) {
  glad_glUniformMatrix4fv(location, count, transpose, value);
}

void drawArrays(GLenum mode, GLint first, GLsizei count) {
  glad_glDrawArrays(mode, first, count);
}

void getIntegerv(GLenum pname, GLint *data) { glad_glGetIntegerv(pname, data); }

void bindTexture(GLenum target, GLuint texture) {
  glad_glBindTexture(target, texture);
}

void bindVertexArray(GLuint array) { glad_glBindVertexArray(array); }

void genTextures(GLsizei n, GLuint *textures) {
  glad_glGenTextures(n, textures);
}

void texParameteri(GLenum target, GLenum pname, GLint param) {
  glad_glTexParameteri(target, pname, param);
}

void pixelStorei(GLenum pname, GLint param) {
  glad_glPixelStorei(pname, param);
}
