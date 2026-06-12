try {
    List<CourseController.CourseWrapper> courses = CourseController.getCourses();
    System.debug('SUCCESS: retrieved ' + courses.size() + ' courses');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getTypeName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
}
