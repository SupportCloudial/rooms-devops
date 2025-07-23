import chartjs from '@salesforce/resourceUrl/ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api } from 'lwc';

import confirmedIncomesLabel from '@salesforce/label/c.rooms_barChart_ConfirmedIncomes';
import potentialIncomesLabel from '@salesforce/label/c.rooms_barChart_potentialIncome';
import probableIncomesLabel from '@salesforce/label/c.rooms_barChart_ProbableIncomes';


export default class ForecastGroupedBarChart extends LightningElement {
    chart;
    chartInitialized = false;

    @api recordId;
    chartData;

    customLabels = {
        probableIncomesLabel,
        confirmedIncomesLabel,
        potentialIncomesLabel
    };

    @api
    get detailData() {
        return this.chartData;
    }

    set detailData(value) {
        this.chartData = value;
        if (value) {
            this.updateChart(); // Use updateChart instead of initializeChart
        }
    }

    renderedCallback() {

        if (this.chartInitialized) {
            return;
        }
        this.chartInitialized = true;

        loadScript(this, chartjs)
            .then(() => {
                this.initializeChart(); // Initialize the chart on first load
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading ChartJS',
                        message: error.message,
                        variant: 'error',
                    })
                );
            });
    }

    initializeChart() {
        const ctx = this.template.querySelector('canvas.barChart').getContext('2d');
        this.chart = new window.Chart(ctx, {
            type: 'bar',


        });

        this.updateChart(); // Populate the chart with data after initialization
    }

    @api
    updateChart() {

        const { probableIncomesLabel, confirmedIncomesLabel, potentialIncomesLabel} = this.customLabels;
        if (!this.chart || !this.chartData) {
            return;
        }

        const potentialIncomes = [];
        const probableIncomes = [];
        const confirmedIncomes = [];
        this.chart.data = {
            labels: [potentialIncomesLabel, probableIncomesLabel, confirmedIncomesLabel ],
            datasets: [
                {
                    label: 'Entry',
                    backgroundColor: [
                        'rgb(75, 192, 192)',
                        'rgb(255, 159, 64)',
                        'rgb(153, 102, 255)'
                    ],
                    data: []
                }
            ]
        };
        this.chart.options ={
            plugins: {
                legend: {
                    display: false // Hide the legend
                }
            },
            responsive : true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    stacked: false,
                },
                y: {
                    beginAtZero: true
                }
            }
        }
        this.chartData.forEach(item => {

            if (item.Opportunity__r) {
                potentialIncomes.push(item.FinalPrice__c);
            } else if (item.Contract__r && item.Contract__r.End_date__c == null) {
                probableIncomes.push(item.FinalPrice__c);
            } else if (item.Contract__r && item.Contract__r.End_date__c != null) {
                confirmedIncomes.push(item.FinalPrice__c);
            }
        });

        this.chart.data.datasets[0].data = [
            this.calculateSum(potentialIncomes),
            this.calculateSum(probableIncomes),
            this.calculateSum(confirmedIncomes)
        ];

        this.chart.update(); // Update the chart with new data
    }

    calculateSum(dataArray) {
        return dataArray.reduce((sum, value) => sum + value, 0);
    }
}