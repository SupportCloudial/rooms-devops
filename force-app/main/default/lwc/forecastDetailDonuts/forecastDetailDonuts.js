import ChartJS from '@salesforce/resourceUrl/ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement } from 'lwc';


export default class ForecastDetailDonuts extends LightningElement {
    chartInit = false;
    chart;
    @api recordId;

    @api
    get detailData() {
        return this.chartData;
    }
    set detailData(value) {
        this.chartData = value;
        if(value){
            this.updateChart();
        }
    }

    // Runs once when the component is rendered to initialize Chart.js
    renderedCallback() {
        if(this.chartInit) {
            return;
        }
        this.chartInit = true;
        Promise.all([
            loadScript(this,ChartJS)
            ]).then(() =>{
                // Get canvas context and create the chart with initial configuration
                const ctx = this.template.querySelector('canvas.pie').getContext('2d');
                this.chart = new window.Chart(ctx, this.config);
            })
            .catch(error =>{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Error loading ChartJS',
                        message : error.message,
                        variant : 'error',
                }),
            );
        });
    }

    config={
        type : 'pie',
        data :{
            datasets :[
            {
                data: [],
                backgroundColor :[
                    'rgb(255,99,132)',
                    'rgb(255,159,64)',
                    'rgb(255,205,86)',
                    'rgb(75,192,192)',
                    'rgb(153,102,204)',
                    'rgb(179,158,181)',
                    'rgb(188,152,126)',
                    'rgb(123,104,238)',
                    'rgb(119,221,119)',],
                label:'Dataset 1'
            }
             ],
        labels:[]
        },
        options: {
            responsive : true,
            maintainAspectRatio: false,
            legend : {
                position :'right'
            },
            animation:{
                animateScale: true,
                animateRotate : true
            }
        }
    };

    // Updates the chart data and appearance whenever detailData is set or changed
    updateChart() {
        if(!this.chart || !this.chart.data){
            console.error("Chart data is not defined yet.");
            return;
        }

        const dataByType = {};

        this.chartData?.forEach(item => {
            console.log('item = ' , JSON.stringify(item));

            if (item.Opportunity__r) {
                dataByType[item.Segmentation__c] = (dataByType[item.Segmentation__c] || 0) + item.FinalPrice__c;
            }
            if (item.Contract__r) {
                dataByType[item.Segmentation__c] = (dataByType[item.Segmentation__c] || 0) + item.FinalPrice__c;
            }
        });

        // Update chart labels and dataset values with accumulated data
        const labels = [...Object.keys(dataByType)];
        const data = [...Object.values(dataByType)];
        const backgroundColors = data.map(() => this.getRandomColor());

        this.chart.data.labels = labels;
        this.chart.data.datasets[0].data = data;
        this.chart.data.datasets[0].backgroundColor = backgroundColors;
        this.chart.update();

    }

    getRandomColor() {
        const hexArray = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'A', 'B', 'C', 'D', 'E', 'F'];
        let code = "";
        for(let i=0; i<6; i++){
         code += hexArray[Math.floor(Math.random()*16)];
        }
        return `#${code}`
    }


}