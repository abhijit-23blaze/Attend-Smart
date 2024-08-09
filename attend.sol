// Import the AccessControl library from OpenZeppelin
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AttendanceSystem is AccessControl {
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    struct Student {
        uint256 attendanceCoins;
        bytes32[] attendedSessions;
    }

    struct Class {
        address teacher;
        string courseId;
        mapping(address => Student) students;
        mapping(bytes32 => bool) validSessions;
    }

    mapping(bytes32 => Class) private classes;

    event AttendanceMarked(address indexed student, uint256 coins, bytes32 classId);

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender); // Grant contract deployer the admin role
    }

    // Modifier to restrict access to teachers
    modifier onlyTeacher(bytes32 classId) {
        require(hasRole(TEACHER_ROLE, msg.sender), "Caller is not a teacher");
        require(classes[classId].teacher == msg.sender, "Caller is not the teacher for this class");
        _;
    }

    // Function to create a new class (only callable by an admin)
    function createClass(bytes32 classId, string memory courseId, address teacher) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(classes[classId].teacher == address(0), "Class already exists");

        classes[classId].teacher = teacher;
        classes[classId].courseId = courseId;

        _grantRole(TEACHER_ROLE, teacher); // Grant teacher role to the assigned teacher
    }

    // Function to add a valid session (only callable by the teacher of the class)
    function addSession(bytes32 classId, bytes32 sessionId) public onlyTeacher(classId) {
        classes[classId].validSessions[sessionId] = true;
    }

    // Function to mark attendance by scanning a QR code
    function markAttendance(bytes32 classId, bytes32 sessionId) public {
        require(classes[classId].students[msg.sender].attendanceCoins >= 0, "Student not registered in this class");
        require(classes[classId].validSessions[sessionId], "Invalid session ID");
        require(!hasAttended(classId, sessionId, msg.sender), "Attendance already marked for this session");

        classes[classId].students[msg.sender].attendanceCoins += 1;
        classes[classId].students[msg.sender].attendedSessions.push(sessionId);

        emit AttendanceMarked(msg.sender, classes[classId].students[msg.sender].attendanceCoins, classId);
    }

    // Function to register a student in a class
    function registerStudent(bytes32 classId) public {
        require(classes[classId].teacher != address(0), "Class does not exist");
        require(classes[classId].students[msg.sender].attendanceCoins == 0, "Student already registered");

        classes[classId].students[msg.sender].attendanceCoins = 0;
    }

    // Function to check student's attendance coins for a specific class
    function getAttendanceCoins(bytes32 classId) public view returns (uint256) {
        require(classes[classId].students[msg.sender].attendanceCoins >= 0, "Student not registered in this class");
        return classes[classId].students[msg.sender].attendanceCoins;
    }

    // Function to check if a student has attended a specific session
    function hasAttended(bytes32 classId, bytes32 sessionId, address student) public view returns (bool) {
        for (uint256 i = 0; i < classes[classId].students[student].attendedSessions.length; i++) {
            if (classes[classId].students[student].attendedSessions[i] == sessionId) {
                return true;
            }
        }
        return false;
    }
}