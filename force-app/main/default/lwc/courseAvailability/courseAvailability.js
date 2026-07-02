import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { publish, MessageContext } from 'lightning/messageService';
import CourseApplyChannel from '@salesforce/messageChannel/CourseApply__c';
import getCourses from '@salesforce/apex/CourseController.getCourses';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FEATURED_COURSE_ORDER = ['btech', 'bca', 'mca', 'mba', 'mtech'];

export default class CourseAvailability extends LightningElement {
    @track allCourses = [];
    @track filteredCourses = [];
    @track selectedType = '';
    @track searchKey = '';
    @track isLoading = false;
    
    // Details Page & Storage properties
    @track showDetailPage = false;
    @track selectedCourse = {};
    @track storedCourseId = '';
    @track applySuccess = false;

    wiredCoursesResult;

    @wire(MessageContext)
    messageContext;

    get typeOptions() {
        return [
            { label: 'All Programs', value: '', pillClass: this.selectedType === '' ? 'filter-pill active' : 'filter-pill' },
            { label: 'Undergraduate', value: 'Undergraduate', pillClass: this.selectedType === 'Undergraduate' ? 'filter-pill active' : 'filter-pill' },
            { label: 'Postgraduate', value: 'Postgraduate', pillClass: this.selectedType === 'Postgraduate' ? 'filter-pill active' : 'filter-pill' },
            { label: 'Diploma', value: 'Diploma', pillClass: this.selectedType === 'Diploma' ? 'filter-pill active' : 'filter-pill' }
        ];
    }

    connectedCallback() {
        // Load stored course selection from storage on initialization
        this.storedCourseId = sessionStorage.getItem('selectedCourseId') || localStorage.getItem('selectedCourseId') || '';
    }

    @wire(getCourses)
    wiredCourses(result) {
        this.wiredCoursesResult = result;
        if (result.data) {
            this.allCourses = result.data.map(wrapper => {
                const course = wrapper.course || {};
                const name = course.Name || 'Course';
                const lowerName = name.toLowerCase();
                const remainingSeats = Math.max(wrapper.remainingSeats || 0, 0);
                const fees = course.Fees__c || 0;
                const courseType = course.Type__c || 'Program';
                const credits = course.Credits__c || 0;
                const capacity = course.Capacity__c || 0;
                const duration = this.getDurationLabel(name, courseType, credits);

                // Dynamic detailed properties (semesters, fee per semester, career opportunities, eligibility)
                const details = this.getDynamicDetails(name, courseType, duration, fees, remainingSeats, capacity);

                return {
                    id: course.Id,
                    name,
                    code: course.Course_Code__c || '',
                    description: course.Description__c || '',
                    fees,
                    formattedFees: this.formatFees(fees),
                    type: courseType,
                    remaining: remainingSeats,
                    capacity: capacity,
                    duration,
                    icon: this.getIconName(name),
                    isFull: remainingSeats <= 0,
                    availabilityClass: remainingSeats <= 0 ? 'availability-badge badge-full' : 'availability-badge badge-open',
                    sortIndex: this.getPreferredOrderIndex(lowerName),
                    ...details
                };
            });

            this.applyFilter();
        } else if (result.error) {
            console.error('Error fetching courses:', result.error);
        }
    }

    handleSearchChange(event) {
        this.searchKey = (event.target.value || '').toLowerCase();
        this.applyFilter();
    }

    handleTypeChange(event) {
        this.selectedType = event.currentTarget.dataset.value;
        this.applyFilter();
    }

    applyFilter() {
        let tempCourses = [...this.allCourses];

        if (this.selectedType) {
            tempCourses = tempCourses.filter(course => course.type === this.selectedType);
        }

        if (this.searchKey) {
            tempCourses = tempCourses.filter(course => {
                const name = (course.name || '').toLowerCase();
                const code = (course.code || '').toLowerCase();
                const description = (course.description || '').toLowerCase();
                return name.includes(this.searchKey) || code.includes(this.searchKey) || description.includes(this.searchKey);
            });
        }

        tempCourses.sort((left, right) => {
            if (left.sortIndex !== right.sortIndex) {
                return left.sortIndex - right.sortIndex;
            }
            return left.name.localeCompare(right.name);
        });

        this.filteredCourses = tempCourses;
    }

    // Opens dedicated details page
    handleOpenDetails(event) {
        const courseId = event.currentTarget.dataset.id;
        const found = this.filteredCourses.find(c => c.id === courseId);
        if (found) {
            this.selectedCourse = found;
            this.showDetailPage = true;
            this.applySuccess = false;
        }
    }

    handleCloseDetails() {
        this.showDetailPage = false;
        this.selectedCourse = {};
        this.applySuccess = false;
    }

    // Apply button at the bottom of the dedicated details page
    handleApplyNow() {
        if (!this.selectedCourse || !this.selectedCourse.id) return;
        
        const courseId = this.selectedCourse.id;

        // Save Course ID to storage (UAT validation checkpoint)
        sessionStorage.setItem('selectedCourseId', courseId);
        localStorage.setItem('selectedCourseId', courseId);
        this.storedCourseId = courseId;
        this.applySuccess = true;

        // Display a standard SLDS Toast Confirmation
        try {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Course selection stored for ${this.selectedCourse.name}.`,
                    variant: 'success'
                })
            );
        } catch (e) {
            console.log('Toast Event failed (running outside Standard Container)');
        }

        // Publish to LMS so any listening subscriber (dashboard) knows a course was selected
        publish(this.messageContext, CourseApplyChannel, {
            courseId: this.selectedCourse.id,
            courseName: this.selectedCourse.name,
            courseType: this.selectedCourse.type,
            courseCode: this.selectedCourse.code,
            courseFees: this.selectedCourse.fees
        });
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredCoursesResult);
        } catch (error) {
            console.error('Error refreshing courses:', error);
        } finally {
            this.isLoading = false;
        }
    }

    get hasCourses() {
        return this.filteredCourses && this.filteredCourses.length > 0;
    }

    getPreferredOrderIndex(lowerName) {
        const preferredIndex = FEATURED_COURSE_ORDER.findIndex(courseName => lowerName.includes(courseName));
        return preferredIndex === -1 ? FEATURED_COURSE_ORDER.length : preferredIndex;
    }

    formatFees(fees) {
        return Number(fees || 0).toLocaleString('en-US');
    }

    getDurationLabel(name, type, credits) {
        const lowerName = (name || '').toLowerCase();
        if (lowerName.includes('btech') || lowerName.includes('b.tech')) {
            return '4 Years';
        }
        if (lowerName.includes('bca')) {
            return '3 Years';
        }
        if (lowerName.includes('mca') || lowerName.includes('mba') || lowerName.includes('mtech') || lowerName.includes('m.tech')) {
            return '2 Years';
        }
        if (type === 'Diploma') {
            return credits >= 40 ? '1 Year' : '6 Months';
        }
        if (type === 'Undergraduate') {
            return '3 Years';
        }
        if (type === 'Postgraduate') {
            return '2 Years';
        }
        return 'Program Duration';
    }

    getIconName(name) {
        const lowerName = (name || '').toLowerCase();
        if (lowerName.includes('btech') || lowerName.includes('mtech') || lowerName.includes('engineering')) {
            return 'utility:connected_apps';
        }
        if (lowerName.includes('bca') || lowerName.includes('mca') || lowerName.includes('computer')) {
            return 'utility:desktop';
        }
        if (lowerName.includes('mba') || lowerName.includes('business')) {
            return 'utility:chart';
        }
        return 'utility:education';
    }

    // Dynamic metadata detail mapper with semester counts & structures
    getDynamicDetails(name, type, duration, fees, remaining, capacity) {
        const semestersCount = duration.includes('4 Years') ? 8 
                             : duration.includes('3 Years') ? 6 
                             : duration.includes('2 Years') ? 4 
                             : duration.includes('1 Year') ? 2 
                             : 1;
        
        const totalSemesters = semestersCount + ' Semesters';
        
        // Fee calculations per semester
        const feePerSemVal = Math.round(fees / semestersCount);
        const formattedFeePerSemester = this.formatFees(feePerSemVal);

        // Generate semesters list for UI display
        const semesterList = [];
        for (let i = 1; i <= semestersCount; i++) {
            semesterList.push('Semester ' + i);
        }
        
        let overview = '';
        let semesterStructure = '';
        let careerPath = '';
        let eligibility = '';

        if (type === 'Undergraduate') {
            overview = 'Comprehensive undergraduate program designed to build strong foundations in academic theory and practical applications.';
            semesterStructure = 'Core subjects in computing and engineering fundamentals. Specialization paths include Full-Stack Engineering, Cloud Architecture, and Data Science.';
            careerPath = 'Software Engineer, Systems Analyst, Business Consultant, Web Developer, database administrator, or research scientist.';
            eligibility = 'Successful completion of 12th standard (High School) or equivalent with a minimum of 60% aggregate marks.';
        } else if (type === 'Postgraduate') {
            overview = 'Advanced postgraduate program designed for deep professional development, research skills, and leadership readiness.';
            semesterStructure = 'Advanced methodologies, specialized core technologies, theory of computing, system architecture, research project and industrial internship.';
            careerPath = 'Lead Technical Specialist, Product/Project Manager, Systems Architect, Lead Developer, Research Fellow, or technical consultant.';
            eligibility = 'Undergraduate degree in a relevant discipline from an accredited university with at least 55% aggregate marks.';
        } else {
            overview = 'Intense professional training program for fast-track career skills, hands-on lab work, and industry certifications.';
            semesterStructure = 'Fundamental principles, scripting, basic laboratory practice, specialization projects, and final placement project.';
            careerPath = 'Assistant Developer, Technical Specialist, Field Support Executive, Systems Administrator, or junior consultant.';
            eligibility = 'Completion of 10th standard or equivalent with high technical inclination.';
        }

        return {
            overview,
            totalSemesters,
            semestersCount,
            semesterList,
            formattedFeePerSemester,
            semesterStructure,
            careerPath,
            eligibility
        };
    }
}